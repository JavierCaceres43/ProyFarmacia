import sql from "mssql";
import { getPool } from "../config/database";

const SELECT_BASE = `
  SELECT
    p.id_producto,
    p.nombre,
    p.concentracion,
    p.adicional,
    p.precio,
    p.unidades_por_envase,
    p.precio_unidad,
    p.avatar,
    p.id_laboratorio,
    p.id_tipo,
    p.id_presentacion,
    l.nombre AS laboratorio,
    t.nombre AS tipo,
    pr.nombre AS presentacion,
    ISNULL((SELECT SUM(stock) FROM dbo.lote WHERE id_producto = p.id_producto AND estado = 1), 0) AS stock,
    p.estado
  FROM dbo.producto p
  INNER JOIN dbo.laboratorio l ON l.id_laboratorio = p.id_laboratorio
  INNER JOIN dbo.tipo t ON t.id_tipo = p.id_tipo
  INNER JOIN dbo.presentacion pr ON pr.id_presentacion = p.id_presentacion
`;

export async function obtenerProductos(q?: string) {
  const db = await getPool();
  const request = db.request();
  let query = SELECT_BASE + ` WHERE p.estado = 1`;
  if (q) {
    request.input("q", sql.NVarChar(100), `%${q}%`);
    query += ` AND (p.nombre LIKE @q OR p.concentracion LIKE @q OR CAST(p.id_producto AS nvarchar(30)) LIKE @q)`;
  }
  query += ` ORDER BY p.nombre;`;
  const result = await request.query(query);
  return result.recordset;
}

export async function obtenerProductoPorId(id: number) {
  const db = await getPool();
  const result = await db.request()
    .input("id_producto", sql.Int, id)
    .query(SELECT_BASE + ` WHERE p.id_producto = @id_producto AND p.estado = 1;`);
  return result.recordset[0] ?? null;
}

function validarReferencias(body: Record<string, unknown>) {
  if (!body.nombre || String(body.nombre).trim() === "")
    fail("El nombre del producto es obligatorio.", 400);
  if (body.precio === undefined || body.precio === null || isNaN(Number(body.precio)) || Number(body.precio) < 0)
    fail("El precio debe ser un número mayor o igual a cero.", 400);
  const unidades = body.unidades_por_envase === undefined || body.unidades_por_envase === null || body.unidades_por_envase === ""
    ? 1 : Number(body.unidades_por_envase);
  if (!Number.isInteger(unidades) || unidades < 1)
    fail("Las unidades por envase deben ser un entero mayor o igual a 1.", 400);
  const precioUnidad = body.precio_unidad === undefined || body.precio_unidad === null || body.precio_unidad === ""
    ? Math.round((Number(body.precio) / unidades) * 100) / 100 : Number(body.precio_unidad);
  if (isNaN(precioUnidad) || precioUnidad < 0)
    fail("El precio por unidad debe ser mayor o igual a cero.", 400);
  (body as any)._unidades = unidades;
  (body as any)._precioUnidad = precioUnidad;
  for (const k of ["id_laboratorio", "id_tipo", "id_presentacion"]) {
    if (!body[k] || isNaN(Number(body[k])))
      fail(`Debe seleccionar ${k.replace("id_", "")}.`, 400);
  }
}

export async function crearProducto(body: Record<string, unknown>) {
  validarReferencias(body);
  const db = await getPool();
  const result = await db.request()
    .input("nombre", sql.NVarChar(150), String(body.nombre).trim())
    .input("concentracion", sql.NVarChar(100), body.concentracion ? String(body.concentracion) : null)
    .input("adicional", sql.NVarChar(200), body.adicional ? String(body.adicional) : null)
    .input("precio", sql.Decimal(10, 2), Number(body.precio))
    .input("unidades", sql.Int, (body as any)._unidades)
    .input("precio_unidad", sql.Decimal(10, 2), (body as any)._precioUnidad)
    .input("avatar", sql.NVarChar(255), body.avatar ? String(body.avatar) : null)
    .input("id_laboratorio", sql.Int, Number(body.id_laboratorio))
    .input("id_tipo", sql.Int, Number(body.id_tipo))
    .input("id_presentacion", sql.Int, Number(body.id_presentacion))
    .query(`
      INSERT INTO dbo.producto
        (nombre, concentracion, adicional, precio, unidades_por_envase, precio_unidad, avatar, id_laboratorio, id_tipo, id_presentacion, estado)
      OUTPUT INSERTED.id_producto
      VALUES
        (@nombre, @concentracion, @adicional, @precio, @unidades, @precio_unidad, @avatar, @id_laboratorio, @id_tipo, @id_presentacion, 1);
    `);
  return obtenerProductoPorId(result.recordset[0].id_producto);
}

export async function actualizarProducto(id: number, body: Record<string, unknown>) {
  validarReferencias(body);
  const db = await getPool();
  const result = await db.request()
    .input("id_producto", sql.Int, id)
    .input("nombre", sql.NVarChar(150), String(body.nombre).trim())
    .input("concentracion", sql.NVarChar(100), body.concentracion ? String(body.concentracion) : null)
    .input("adicional", sql.NVarChar(200), body.adicional ? String(body.adicional) : null)
    .input("precio", sql.Decimal(10, 2), Number(body.precio))
    .input("unidades", sql.Int, (body as any)._unidades)
    .input("precio_unidad", sql.Decimal(10, 2), (body as any)._precioUnidad)
    .input("avatar", sql.NVarChar(255), body.avatar ? String(body.avatar) : null)
    .input("id_laboratorio", sql.Int, Number(body.id_laboratorio))
    .input("id_tipo", sql.Int, Number(body.id_tipo))
    .input("id_presentacion", sql.Int, Number(body.id_presentacion))
    .query(`
      UPDATE dbo.producto
      SET nombre = @nombre,
          concentracion = @concentracion,
          adicional = @adicional,
          precio = @precio,
          unidades_por_envase = @unidades,
          precio_unidad = @precio_unidad,
          avatar = @avatar,
          id_laboratorio = @id_laboratorio,
          id_tipo = @id_tipo,
          id_presentacion = @id_presentacion
      WHERE id_producto = @id_producto AND estado = 1;
    `);
  if (result.rowsAffected[0] === 0) return null;
  return obtenerProductoPorId(id);
}

export async function actualizarAvatar(id: number, avatar: string) {
  const db = await getPool();
  const prev = await db.request()
    .input("id", sql.Int, id)
    .query(`SELECT avatar FROM dbo.producto WHERE id_producto = @id;`);
  if (prev.recordset.length === 0) return null;
  await db.request()
    .input("id2", sql.Int, id)
    .input("avatar", sql.NVarChar(255), avatar)
    .query(`UPDATE dbo.producto SET avatar = @avatar WHERE id_producto = @id2 AND estado = 1;`);
  return { id, avatar, anterior: prev.recordset[0].avatar as string | null };
}

export async function desactivarProducto(id: number) {
  const db = await getPool();
  const result = await db.request()
    .input("id_producto", sql.Int, id)
    .query(`UPDATE dbo.producto SET estado = 0 WHERE id_producto = @id_producto AND estado = 1;`);
  return result.rowsAffected[0] > 0;
}

function fail(message: string, statusCode: number): never {
  const e = new Error(message) as any;
  e.statusCode = statusCode;
  throw e;
}
