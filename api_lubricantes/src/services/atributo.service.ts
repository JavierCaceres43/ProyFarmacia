import sql from "mssql";
import { getPool } from "../config/database";

const TABLAS: Record<string, { tabla: string; id: string }> = {
  laboratorio: { tabla: "dbo.laboratorio", id: "id_laboratorio" },
  tipo: { tabla: "dbo.tipo", id: "id_tipo" },
  presentacion: { tabla: "dbo.presentacion", id: "id_presentacion" }
};

function mapa(tabla: string) {
  const m = TABLAS[String(tabla).toLowerCase()];
  if (!m) fail(`Tabla de atributo inválida: ${tabla}. Use laboratorio, tipo o presentacion.`, 400);
  return m;
}

export function tablasValidas() {
  return Object.keys(TABLAS);
}

export async function listar(tabla: string) {
  const m = mapa(tabla);
  const db = await getPool();
  const extra = String(tabla).toLowerCase() === "laboratorio" ? ", logo" : "";
  const result = await db.request().query(
    `SELECT ${m.id} AS id, nombre, estado${extra} FROM ${m.tabla} WHERE estado = 1 ORDER BY nombre;`
  );
  return result.recordset;
}

export async function actualizarLogo(id: number, logo: string) {
  const db = await getPool();
  const prev = await db.request()
    .input("id", sql.Int, id)
    .query(`SELECT logo FROM dbo.laboratorio WHERE id_laboratorio = @id;`);
  if (prev.recordset.length === 0) return null;
  await db.request()
    .input("id2", sql.Int, id)
    .input("logo", sql.NVarChar(255), logo)
    .query(`UPDATE dbo.laboratorio SET logo = @logo WHERE id_laboratorio = @id2 AND estado = 1;`);
  return { id, logo, anterior: prev.recordset[0].logo as string | null };
}

export async function crear(tabla: string, nombre: unknown) {
  const m = mapa(tabla);
  if (!nombre || String(nombre).trim() === "") fail("El nombre es obligatorio.", 400);
  const db = await getPool();
  const result = await db.request()
    .input("nombre", sql.NVarChar(100), String(nombre).trim())
    .query(`INSERT INTO ${m.tabla} (nombre, estado) OUTPUT INSERTED.${m.id} AS id VALUES (@nombre, 1);`);
  return { id: result.recordset[0].id, nombre: String(nombre).trim() };
}

export async function actualizar(tabla: string, id: number, nombre: unknown) {
  const m = mapa(tabla);
  if (!nombre || String(nombre).trim() === "") fail("El nombre es obligatorio.", 400);
  const db = await getPool();
  const result = await db.request()
    .input("id", sql.Int, id)
    .input("nombre", sql.NVarChar(100), String(nombre).trim())
    .query(`UPDATE ${m.tabla} SET nombre = @nombre WHERE ${m.id} = @id AND estado = 1;`);
  if (result.rowsAffected[0] === 0) return null;
  return { id, nombre: String(nombre).trim() };
}

export async function eliminar(tabla: string, id: number) {
  const m = mapa(tabla);
  const db = await getPool();
  try {
    const result = await db.request()
      .input("id", sql.Int, id)
      .query(`UPDATE ${m.tabla} SET estado = 0 WHERE ${m.id} = @id AND estado = 1;`);
    return result.rowsAffected[0] > 0;
  } catch (e: any) {
    if (e?.number === 547) fail("No se puede eliminar: está en uso por productos.", 409);
    throw e;
  }
}

function fail(message: string, statusCode: number): never {
  const e = new Error(message) as any;
  e.statusCode = statusCode;
  throw e;
}
