import sql from "mssql";
import { getPool } from "../config/database";

const SELECT_BASE = `
  SELECT
    l.codigo,
    l.id_producto,
    l.id_proveedor,
    l.stock,
    l.fecha_vencimiento,
    p.nombre AS producto,
    pr.nombre AS proveedor,
    l.estado
  FROM dbo.lote l
  INNER JOIN dbo.producto p ON p.id_producto = l.id_producto
  INNER JOIN dbo.proveedor pr ON pr.id_proveedor = l.id_proveedor
`;

export async function obtenerLotes(q?: string) {
  const db = await getPool();
  const request = db.request();
  let query = SELECT_BASE + ` WHERE l.estado = 1`;
  if (q) {
    request.input("q", sql.NVarChar(100), `%${q}%`);
    query += ` AND (p.nombre LIKE @q OR pr.nombre LIKE @q OR CAST(l.codigo AS nvarchar(30)) LIKE @q)`;
  }
  query += ` ORDER BY l.fecha_vencimiento;`;
  const result = await request.query(query);
  return result.recordset;
}

export async function obtenerLotePorCodigo(codigo: number) {
  const db = await getPool();
  const result = await db.request()
    .input("codigo", sql.Int, codigo)
    .query(SELECT_BASE + ` WHERE l.codigo = @codigo AND l.estado = 1;`);
  return result.recordset[0] ?? null;
}

export async function crearLote(body: Record<string, unknown>) {
  const stock = Number(body.stock);
  if (!body.id_producto || isNaN(Number(body.id_producto))) fail("Debe indicar el producto.", 400);
  if (!body.id_proveedor || isNaN(Number(body.id_proveedor))) fail("Debe seleccionar el proveedor.", 400);
  if (isNaN(stock) || stock < 0) fail("El stock debe ser mayor o igual a cero.", 400);
  if (!body.fecha_vencimiento) fail("Debe indicar la fecha de vencimiento.", 400);

  const db = await getPool();
  const result = await db.request()
    .input("id_producto", sql.Int, Number(body.id_producto))
    .input("id_proveedor", sql.Int, Number(body.id_proveedor))
    .input("stock", sql.Int, stock)
    .input("fecha_vencimiento", sql.Date, new Date(String(body.fecha_vencimiento)))
    .query(`
      INSERT INTO dbo.lote (id_producto, id_proveedor, stock, fecha_vencimiento, estado)
      OUTPUT INSERTED.codigo
      VALUES (@id_producto, @id_proveedor, @stock, @fecha_vencimiento, 1);
    `);
  return obtenerLotePorCodigo(result.recordset[0].codigo);
}

export async function actualizarLote(codigo: number, body: Record<string, unknown>) {
  const db = await getPool();
  const sets: string[] = [];
  const request = db.request().input("codigo", sql.Int, codigo);
  if (body.stock !== undefined) {
    const stock = Number(body.stock);
    if (isNaN(stock) || stock < 0) fail("El stock debe ser mayor o igual a cero.", 400);
    request.input("stock", sql.Int, stock);
    sets.push("stock = @stock");
  }
  if (body.fecha_vencimiento) {
    request.input("fecha_vencimiento", sql.Date, new Date(String(body.fecha_vencimiento)));
    sets.push("fecha_vencimiento = @fecha_vencimiento");
  }
  if (sets.length === 0) fail("Nada que actualizar.", 400);
  const result = await request.query(
    `UPDATE dbo.lote SET ${sets.join(", ")} WHERE codigo = @codigo AND estado = 1;`
  );
  if (result.rowsAffected[0] === 0) return null;
  return obtenerLotePorCodigo(codigo);
}

export async function eliminarLote(codigo: number) {
  const db = await getPool();
  const result = await db.request()
    .input("codigo", sql.Int, codigo)
    .query(`UPDATE dbo.lote SET estado = 0 WHERE codigo = @codigo AND estado = 1;`);
  return result.rowsAffected[0] > 0;
}

function fail(message: string, statusCode: number): never {
  const e = new Error(message) as any;
  e.statusCode = statusCode;
  throw e;
}
