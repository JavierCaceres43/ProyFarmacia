import sql from "mssql";
import { getPool } from "../config/database";

export async function obtenerProveedores(q?: string) {
  const db = await getPool();
  const request = db.request();
  let query = `SELECT id_proveedor, nombre, telefono, correo, direccion, avatar, estado
               FROM dbo.proveedor WHERE estado = 1`;
  if (q) {
    request.input("q", sql.NVarChar(100), `%${q}%`);
    query += ` AND (nombre LIKE @q OR CAST(id_proveedor AS nvarchar(30)) LIKE @q)`;
  }
  query += ` ORDER BY nombre;`;
  const result = await request.query(query);
  return result.recordset;
}

export async function obtenerProveedorPorId(id: number) {
  const db = await getPool();
  const result = await db.request()
    .input("id_proveedor", sql.Int, id)
    .query(`SELECT id_proveedor, nombre, telefono, correo, direccion, avatar, estado
            FROM dbo.proveedor WHERE id_proveedor = @id_proveedor AND estado = 1;`);
  return result.recordset[0] ?? null;
}

export async function crearProveedor(body: Record<string, unknown>) {
  if (!body.nombre || String(body.nombre).trim() === "")
    fail("El nombre del proveedor es obligatorio.", 400);
  const db = await getPool();
  const result = await db.request()
    .input("nombre", sql.NVarChar(150), String(body.nombre).trim())
    .input("telefono", sql.NVarChar(30), body.telefono ? String(body.telefono) : null)
    .input("correo", sql.NVarChar(150), body.correo ? String(body.correo) : null)
    .input("direccion", sql.NVarChar(200), body.direccion ? String(body.direccion) : null)
    .query(`
      INSERT INTO dbo.proveedor (nombre, telefono, correo, direccion, estado)
      OUTPUT INSERTED.id_proveedor
      VALUES (@nombre, @telefono, @correo, @direccion, 1);
    `);
  return obtenerProveedorPorId(result.recordset[0].id_proveedor);
}

export async function actualizarProveedor(id: number, body: Record<string, unknown>) {
  if (!body.nombre || String(body.nombre).trim() === "")
    fail("El nombre del proveedor es obligatorio.", 400);
  const db = await getPool();
  const result = await db.request()
    .input("id_proveedor", sql.Int, id)
    .input("nombre", sql.NVarChar(150), String(body.nombre).trim())
    .input("telefono", sql.NVarChar(30), body.telefono ? String(body.telefono) : null)
    .input("correo", sql.NVarChar(150), body.correo ? String(body.correo) : null)
    .input("direccion", sql.NVarChar(200), body.direccion ? String(body.direccion) : null)
    .query(`
      UPDATE dbo.proveedor
      SET nombre = @nombre, telefono = @telefono, correo = @correo, direccion = @direccion
      WHERE id_proveedor = @id_proveedor AND estado = 1;
    `);
  if (result.rowsAffected[0] === 0) return null;
  return obtenerProveedorPorId(id);
}

export async function actualizarAvatar(id: number, avatar: string) {
  const db = await getPool();
  const prev = await db.request()
    .input("id", sql.Int, id)
    .query(`SELECT avatar FROM dbo.proveedor WHERE id_proveedor = @id;`);
  if (prev.recordset.length === 0) return null;
  await db.request()
    .input("id2", sql.Int, id)
    .input("avatar", sql.NVarChar(255), avatar)
    .query(`UPDATE dbo.proveedor SET avatar = @avatar WHERE id_proveedor = @id2 AND estado = 1;`);
  return { id, avatar, anterior: prev.recordset[0].avatar as string | null };
}

export async function eliminarProveedor(id: number) {
  const db = await getPool();
  const result = await db.request()
    .input("id_proveedor", sql.Int, id)
    .query(`UPDATE dbo.proveedor SET estado = 0 WHERE id_proveedor = @id_proveedor AND estado = 1;`);
  return result.rowsAffected[0] > 0;
}

function fail(message: string, statusCode: number): never {
  const e = new Error(message) as any;
  e.statusCode = statusCode;
  throw e;
}
