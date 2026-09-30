import sql from "mssql";
import { getPool } from "../config/database";

export async function obtenerVentas(q?: string) {
  const db = await getPool();
  const request = db.request();
  let query = `
    SELECT v.codigo, v.fecha, v.cliente, v.dni_cliente, v.total, v.usuario_dni, u.nombre AS vendedor, v.estado
    FROM dbo.venta v
    INNER JOIN dbo.usuario u ON u.dni = v.usuario_dni
    WHERE v.estado = 1`;
  if (q) {
    request.input("q", sql.NVarChar(100), `%${q}%`);
    query += ` AND (v.cliente LIKE @q OR CAST(v.codigo AS nvarchar(30)) LIKE @q OR u.nombre LIKE @q)`;
  }
  query += ` ORDER BY v.fecha DESC;`;
  const result = await request.query(query);
  return result.recordset;
}

export async function obtenerVentaPorCodigo(codigo: number) {
  const db = await getPool();
  const cab = await db.request()
    .input("codigo", sql.Int, codigo)
    .query(`
      SELECT v.codigo, v.fecha, v.cliente, v.dni_cliente, v.total, v.usuario_dni, u.nombre AS vendedor, v.estado
      FROM dbo.venta v
      INNER JOIN dbo.usuario u ON u.dni = v.usuario_dni
      WHERE v.codigo = @codigo AND v.estado = 1;
    `);
  if (cab.recordset.length === 0) return null;
  const items = await db.request()
    .input("codigo2", sql.Int, codigo)
    .query(`
      SELECT d.cantidad, d.precio, d.subtotal, p.nombre AS producto,
             p.concentracion, p.adicional, lab.nombre AS laboratorio,
             pr.nombre AS presentacion, t.nombre AS tipo,
             (ISNULL(p.concentracion, N'') + N' ' + ISNULL(p.adicional, N'')) AS detalle
      FROM dbo.detalle_venta d
      INNER JOIN dbo.lote lo ON lo.codigo = d.lote_codigo
      INNER JOIN dbo.producto p ON p.id_producto = lo.id_producto
      INNER JOIN dbo.laboratorio lab ON lab.id_laboratorio = p.id_laboratorio
      INNER JOIN dbo.presentacion pr ON pr.id_presentacion = p.id_presentacion
      INNER JOIN dbo.tipo t ON t.id_tipo = p.id_tipo
      WHERE d.venta_codigo = @codigo2;
    `);
  return { ...cab.recordset[0], items: items.recordset };
}

export async function resumenVentas(dni?: string) {
  const db = await getPool();
  const request = db.request();
  if (dni) request.input("dni", sql.NVarChar(20), dni);
  const result = await request.query(`
    DECLARE @ahora DATETIME2 = DATEADD(HOUR, -4, SYSUTCDATETIME());
    SELECT
      ISNULL((SELECT SUM(total) FROM dbo.venta WHERE estado = 1 AND CAST(fecha AS DATE) = CAST(@ahora AS DATE)), 0) AS total_dia,
      ISNULL((SELECT SUM(total) FROM dbo.venta WHERE estado = 1 AND CAST(fecha AS DATE) = CAST(@ahora AS DATE) ${dni ? "AND usuario_dni = @dni" : ""}), 0) AS dia_vendedor,
      ISNULL((SELECT SUM(total) FROM dbo.venta WHERE estado = 1 AND YEAR(fecha) = YEAR(@ahora) AND MONTH(fecha) = MONTH(@ahora)), 0) AS mensual,
      ISNULL((SELECT SUM(total) FROM dbo.venta WHERE estado = 1 AND YEAR(fecha) = YEAR(@ahora)), 0) AS anual;
  `);
  return result.recordset[0];
}

interface ItemVenta { id_producto: number; cantidad: number; }

export async function crearVenta(body: Record<string, unknown>) {
  const cliente = String(body.cliente ?? "").trim();
  const usuario_dni = String(body.usuario_dni ?? "").trim();
  const items = body.items as ItemVenta[] | undefined;
  if (cliente === "") fail("El cliente es obligatorio.", 400);
  if (usuario_dni === "") fail("Debe indicar el vendedor (usuario_dni).", 400);
  if (!Array.isArray(items) || items.length === 0) fail("La venta debe tener al menos un producto.", 400);

  const db = await getPool();
  const tx = new sql.Transaction(db);
  await tx.begin();
  try {
    const vUsr = new sql.Request(tx);
    const usr = await vUsr
      .input("dni", sql.NVarChar(20), usuario_dni)
      .query(`SELECT dni FROM dbo.usuario WHERE dni = @dni AND estado = 1;`);
    if (usr.recordset.length === 0) fail("El vendedor no existe o está inactivo.", 400);

    const rVenta = new sql.Request(tx);
    const ins = await rVenta
      .input("cliente", sql.NVarChar(150), cliente)
      .input("dni_cliente", sql.NVarChar(20), body.dni_cliente ? String(body.dni_cliente) : null)
      .input("usuario_dni", sql.NVarChar(20), usuario_dni)
      .query(`
        INSERT INTO dbo.venta (fecha, cliente, dni_cliente, total, usuario_dni, estado)
        OUTPUT INSERTED.codigo
        VALUES (DATEADD(HOUR, -4, SYSUTCDATETIME()), @cliente, @dni_cliente, 0, @usuario_dni, 1);
      `);
    const codigo: number = ins.recordset[0].codigo;
    let total = 0;

    for (const it of items) {
      const id_producto = Number(it.id_producto);
      let cantidad = Number(it.cantidad);
      if (!id_producto || !Number.isInteger(cantidad) || cantidad <= 0)
        fail("Cada ítem debe tener id_producto y cantidad entera mayor a cero (unidades).", 400);

      const rProd = new sql.Request(tx);
      const prod = await rProd
        .input("idp", sql.Int, id_producto)
        .query(`SELECT id_producto, precio_unidad FROM dbo.producto WHERE id_producto = @idp AND estado = 1;`);
      if (prod.recordset.length === 0) fail(`El producto ${id_producto} no existe o está inactivo.`, 400);
      const precio: number = Number(prod.recordset[0].precio_unidad);

      // Lotes con stock, primero los que vencen antes (FIFO por vencimiento).
      const rLotes = new sql.Request(tx);
      const lotes = await rLotes
        .input("idp2", sql.Int, id_producto)
        .query(`SELECT codigo, stock FROM dbo.lote
                WHERE id_producto = @idp2 AND estado = 1 AND stock > 0
                ORDER BY fecha_vencimiento;`);
      const disponible = lotes.recordset.reduce((a: number, l: any) => a + l.stock, 0);
      if (disponible < cantidad)
        fail(`Stock insuficiente para el producto ${id_producto} (disponible ${disponible}).`, 400);

      for (const lote of lotes.recordset) {
        if (cantidad <= 0) break;
        const toma = Math.min(cantidad, lote.stock);
        const subtotal = toma * precio;
        const rDet = new sql.Request(tx);
        await rDet
          .input("vc", sql.Int, codigo)
          .input("lc", sql.Int, lote.codigo)
          .input("cant", sql.Int, toma)
          .input("pre", sql.Decimal(10, 2), precio)
          .input("sub", sql.Decimal(10, 2), subtotal)
          .query(`INSERT INTO dbo.detalle_venta (venta_codigo, lote_codigo, cantidad, precio, subtotal)
                  VALUES (@vc, @lc, @cant, @pre, @sub);`);
        const rUpd = new sql.Request(tx);
        await rUpd
          .input("lc2", sql.Int, lote.codigo)
          .input("toma", sql.Int, toma)
          .query(`UPDATE dbo.lote SET stock = stock - @toma WHERE codigo = @lc2;`);
        cantidad -= toma;
        total += subtotal;
      }
    }

    const rTot = new sql.Request(tx);
    await rTot
      .input("vc2", sql.Int, codigo)
      .input("total", sql.Decimal(10, 2), total)
      .query(`UPDATE dbo.venta SET total = @total WHERE codigo = @vc2;`);

    await tx.commit();
    return obtenerVentaPorCodigo(codigo);
  } catch (e) {
    try { await tx.rollback(); } catch { /* ignorar */ }
    throw e;
  }
}

export async function anularVenta(codigo: number) {
  const db = await getPool();
  const tx = new sql.Transaction(db);
  await tx.begin();
  try {
    // Devuelve el stock a los lotes antes de anular.
    const rDet = new sql.Request(tx);
    const det = await rDet
      .input("vc", sql.Int, codigo)
      .query(`SELECT lote_codigo, cantidad FROM dbo.detalle_venta WHERE venta_codigo = @vc;`);
    if (det.recordset.length === 0) {
      const rV = new sql.Request(tx);
      const v = await rV
        .input("vc2", sql.Int, codigo)
        .query(`SELECT codigo FROM dbo.venta WHERE codigo = @vc2 AND estado = 1;`);
      if (v.recordset.length === 0) { await tx.rollback(); return false; }
    }
    for (const d of det.recordset) {
      const rDev = new sql.Request(tx);
      await rDev
        .input("lc", sql.Int, d.lote_codigo)
        .input("cant", sql.Int, d.cantidad)
        .query(`UPDATE dbo.lote SET stock = stock + @cant WHERE codigo = @lc;`);
    }
    const rAnu = new sql.Request(tx);
    await rAnu
      .input("vc3", sql.Int, codigo)
      .query(`UPDATE dbo.venta SET estado = 0 WHERE codigo = @vc3 AND estado = 1;`);
    await tx.commit();
    return true;
  } catch (e) {
    try { await tx.rollback(); } catch { /* ignorar */ }
    throw e;
  }
}

function fail(message: string, statusCode: number): never {
  const e = new Error(message) as any;
  e.statusCode = statusCode;
  throw e;
}
