import sql from "mssql";
import { getPool } from "../config/database";

export async function obtenerProveedores(q?: string) {
  const db = await getPool();
  const request = db.request();
  let query = `SELECT pr.id_proveedor, pr.nombre, pr.telefono, pr.correo, pr.direccion, pr.avatar,
                      pr.id_laboratorio, l.nombre AS laboratorio, pr.estado
               FROM dbo.proveedor pr
               LEFT JOIN dbo.laboratorio l ON l.id_laboratorio = pr.id_laboratorio
               WHERE pr.estado = 1`;
  if (q) {
    request.input("q", sql.NVarChar(100), `%${q}%`);
    query += ` AND (pr.nombre LIKE @q OR CAST(pr.id_proveedor AS nvarchar(30)) LIKE @q)`;
  }
  query += ` ORDER BY pr.nombre;`;
  const result = await request.query(query);
  return result.recordset;
}

export async function obtenerProveedorPorId(id: number) {
  const db = await getPool();
  const result = await db.request()
    .input("id_proveedor", sql.Int, id)
    .query(`SELECT pr.id_proveedor, pr.nombre, pr.telefono, pr.correo, pr.direccion, pr.avatar,
                   pr.id_laboratorio, l.nombre AS laboratorio, pr.estado
            FROM dbo.proveedor pr
            LEFT JOIN dbo.laboratorio l ON l.id_laboratorio = pr.id_laboratorio
            WHERE pr.id_proveedor = @id_proveedor AND pr.estado = 1;`);
  return result.recordset[0] ?? null;
}

async function validarLaboratorio(db: sql.ConnectionPool, id_laboratorio: unknown) {
  if (id_laboratorio === undefined || id_laboratorio === null || id_laboratorio === "") return null;
  const id = Number(id_laboratorio);
  if (!Number.isInteger(id) || id < 1) fail("Laboratorio inválido.", 400);
  const r = await db.request()
    .input("id_lab", sql.Int, id)
    .query(`SELECT id_laboratorio FROM dbo.laboratorio WHERE id_laboratorio = @id_lab AND estado = 1;`);
  if (r.recordset.length === 0) fail("El laboratorio no existe o está inactivo.", 400);
  return id;
}

export async function crearProveedor(body: Record<string, unknown>) {
  if (!body.nombre || String(body.nombre).trim() === "")
    fail("El nombre del proveedor es obligatorio.", 400);
  const db = await getPool();
  const idLab = await validarLaboratorio(db, body.id_laboratorio);
  const result = await db.request()
    .input("nombre", sql.NVarChar(150), String(body.nombre).trim())
    .input("telefono", sql.NVarChar(30), body.telefono ? String(body.telefono) : null)
    .input("correo", sql.NVarChar(150), body.correo ? String(body.correo) : null)
    .input("direccion", sql.NVarChar(200), body.direccion ? String(body.direccion) : null)
    .input("id_laboratorio", sql.Int, idLab)
    .query(`
      INSERT INTO dbo.proveedor (nombre, telefono, correo, direccion, id_laboratorio, estado)
      OUTPUT INSERTED.id_proveedor
      VALUES (@nombre, @telefono, @correo, @direccion, @id_laboratorio, 1);
    `);
  return obtenerProveedorPorId(result.recordset[0].id_proveedor);
}

export async function actualizarProveedor(id: number, body: Record<string, unknown>) {
  if (!body.nombre || String(body.nombre).trim() === "")
    fail("El nombre del proveedor es obligatorio.", 400);
  const db = await getPool();
  const idLab = await validarLaboratorio(db, body.id_laboratorio);
  const result = await db.request()
    .input("id_proveedor", sql.Int, id)
    .input("nombre", sql.NVarChar(150), String(body.nombre).trim())
    .input("telefono", sql.NVarChar(30), body.telefono ? String(body.telefono) : null)
    .input("correo", sql.NVarChar(150), body.correo ? String(body.correo) : null)
    .input("direccion", sql.NVarChar(200), body.direccion ? String(body.direccion) : null)
    .input("id_laboratorio", sql.Int, idLab)
    .query(`
      UPDATE dbo.proveedor
      SET nombre = @nombre, telefono = @telefono, correo = @correo, direccion = @direccion,
          id_laboratorio = @id_laboratorio
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
