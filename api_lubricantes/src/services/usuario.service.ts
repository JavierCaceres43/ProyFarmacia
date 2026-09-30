import sql from "mssql";
import { getPool } from "../config/database";

const SELECT_SIN_PASSWORD = `
  SELECT dni, nombre, edad, tipo_usuario, telefono, residencia, correo, sexo, info_adicional, avatar, estado
  FROM dbo.usuario
`;

export async function obtenerUsuarios(q?: string) {
  const db = await getPool();
  const request = db.request();
  let query = SELECT_SIN_PASSWORD + ` WHERE estado = 1`;
  if (q) {
    request.input("q", sql.NVarChar(100), `%${q}%`);
    query += ` AND (nombre LIKE @q OR dni LIKE @q)`;
  }
  query += ` ORDER BY nombre;`;
  const result = await request.query(query);
  return result.recordset;
}

export async function obtenerUsuarioPorDni(dni: string) {
  const db = await getPool();
  const result = await db.request()
    .input("dni", sql.NVarChar(20), dni)
    .query(SELECT_SIN_PASSWORD + ` WHERE dni = @dni AND estado = 1;`);
  return result.recordset[0] ?? null;
}

export async function crearUsuario(body: Record<string, unknown>) {
  const dni = String(body.dni ?? "").trim();
  const nombre = String(body.nombre ?? "").trim();
  if (dni === "") fail("El C.I. es obligatorio.", 400);
  if (nombre === "") fail("El nombre es obligatorio.", 400);
  if (body.tipo_usuario && String(body.tipo_usuario) === "Root")
    fail("Ya existe un usuario Root en el sistema.", 400);
  const db = await getPool();
  const existe = await db.request()
    .input("dni", sql.NVarChar(20), dni)
    .query(`SELECT dni FROM dbo.usuario WHERE dni = @dni;`);
  if (existe.recordset.length > 0) fail("Ya existe un usuario con ese C.I.", 409);
  const hayNombre = await db.request()
    .input("nom", sql.NVarChar(150), nombre)
    .query(`SELECT dni FROM dbo.usuario WHERE nombre = @nom;`);
  if (hayNombre.recordset.length > 0) fail("Ya existe un usuario con ese nombre.", 409);

  await db.request()
    .input("dni", sql.NVarChar(20), dni)
    .input("nombre", sql.NVarChar(150), nombre)
    .input("edad", sql.Int, body.edad !== undefined && body.edad !== null && body.edad !== "" ? Number(body.edad) : null)
    .input("tipo_usuario", sql.NVarChar(20), body.tipo_usuario ? String(body.tipo_usuario) : "Encargado")
    .input("telefono", sql.NVarChar(30), body.telefono ? String(body.telefono) : null)
    .input("residencia", sql.NVarChar(200), body.residencia ? String(body.residencia) : null)
    .input("correo", sql.NVarChar(150), body.correo ? String(body.correo) : null)
    .input("sexo", sql.NVarChar(20), body.sexo ? String(body.sexo) : null)
    .input("info_adicional", sql.NVarChar(300), body.info_adicional ? String(body.info_adicional) : null)
    .input("password", sql.NVarChar(255), body.password ? String(body.password) : dni)
    .query(`
      INSERT INTO dbo.usuario
        (dni, nombre, edad, tipo_usuario, telefono, residencia, correo, sexo, info_adicional, password, estado)
      VALUES
        (@dni, @nombre, @edad, @tipo_usuario, @telefono, @residencia, @correo, @sexo, @info_adicional, @password, 1);
    `);
  return obtenerUsuarioPorDni(dni);
}

export async function actualizarUsuario(dni: string, body: Record<string, unknown>) {
  const db = await getPool();
  const sets: string[] = [];
  const request = db.request().input("dni", sql.NVarChar(20), dni);
  const texto = (k: string, n: number) => {
    if (body[k] !== undefined) {
      request.input(k, sql.NVarChar(n), body[k] ? String(body[k]) : null);
      sets.push(`${k} = @${k}`);
    }
  };
  texto("nombre", 150); texto("telefono", 30); texto("residencia", 200);
  texto("correo", 150); texto("sexo", 20); texto("info_adicional", 300);
  if (body.edad !== undefined) {
    request.input("edad", sql.Int, body.edad === null || body.edad === "" ? null : Number(body.edad));
    sets.push("edad = @edad");
  }
  if (body.password_nuevo) {
    if (!body.password_actual) fail("Debe indicar la contraseña actual.", 400);
    const actual = await db.request()
      .input("dni2", sql.NVarChar(20), dni)
      .query(`SELECT password FROM dbo.usuario WHERE dni = @dni2 AND estado = 1;`);
    if (actual.recordset.length === 0) return null;
    if (String(actual.recordset[0].password) !== String(body.password_actual))
      fail("La contraseña actual no es correcta.", 400);
    request.input("password", sql.NVarChar(255), String(body.password_nuevo));
    sets.push("password = @password");
  }
  if (sets.length === 0) fail("Nada que actualizar.", 400);
  const result = await request.query(
    `UPDATE dbo.usuario SET ${sets.join(", ")} WHERE dni = @dni AND estado = 1;`
  );
  if (result.rowsAffected[0] === 0) return null;
  return obtenerUsuarioPorDni(dni);
}

const ORDEN_TIPO = ["Encargado", "Administrador", "Root"];

async function esUnicoRoot(dni: string) {
  const db = await getPool();
  const total = await db.request()
    .query(`SELECT COUNT(*) AS n FROM dbo.usuario WHERE tipo_usuario = N'Root' AND estado = 1;`);
  if (Number(total.recordset[0].n) !== 1) return false;
  const uno = await db.request()
    .input("d", sql.NVarChar(20), dni)
    .query(`SELECT tipo_usuario FROM dbo.usuario WHERE dni = @d AND estado = 1;`);
  return uno.recordset.length > 0 && uno.recordset[0].tipo_usuario === "Root";
}

export async function cambiarTipo(dni: string, sentido: string, solicitadoPor?: unknown) {
  const actual = await obtenerUsuarioPorDni(dni);
  if (!actual) return null;
  if (actual.tipo_usuario === "Administrador" && sentido === "down") {
    const db = await getPool();
    const sol = await db.request()
      .input("s", sql.NVarChar(20), solicitadoPor ? String(solicitadoPor) : "")
      .query(`SELECT tipo_usuario FROM dbo.usuario WHERE dni = @s AND estado = 1;`);
    if (sol.recordset.length === 0 || sol.recordset[0].tipo_usuario !== "Root")
      fail("Solo el usuario Root puede descender administradores.", 403);
  }
  let idx = ORDEN_TIPO.indexOf(actual.tipo_usuario);
  if (sentido === "up" && idx < ORDEN_TIPO.length - 1) idx++;
  else if (sentido === "down" && idx > 0) idx--;
  else fail("No se puede cambiar más el tipo de usuario.", 400);
  if (ORDEN_TIPO[idx] === "Root")
    fail("Ya existe un usuario Root en el sistema.", 400);
  if (sentido === "down" && await esUnicoRoot(dni))
    fail("No se puede descender al único Root del sistema.", 400);
  const db = await getPool();
  await db.request()
    .input("dni", sql.NVarChar(20), dni)
    .input("tipo_usuario", sql.NVarChar(20), ORDEN_TIPO[idx])
    .query(`UPDATE dbo.usuario SET tipo_usuario = @tipo_usuario WHERE dni = @dni AND estado = 1;`);
  return obtenerUsuarioPorDni(dni);
}

export async function actualizarAvatar(dni: string, avatar: string) {
  const db = await getPool();
  const prev = await db.request()
    .input("dni", sql.NVarChar(20), dni)
    .query(`SELECT avatar FROM dbo.usuario WHERE dni = @dni;`);
  if (prev.recordset.length === 0) return null;
  await db.request()
    .input("dni2", sql.NVarChar(20), dni)
    .input("avatar", sql.NVarChar(255), avatar)
    .query(`UPDATE dbo.usuario SET avatar = @avatar WHERE dni = @dni2 AND estado = 1;`);
  return { dni, avatar, anterior: prev.recordset[0].avatar as string | null };
}

export async function eliminarUsuario(dni: string, solicitadoPor?: unknown) {
  const db = await getPool();
  const sol = await db.request()
    .input("s", sql.NVarChar(20), solicitadoPor ? String(solicitadoPor) : "")
    .query(`SELECT tipo_usuario FROM dbo.usuario WHERE dni = @s AND estado = 1;`);
  if (sol.recordset.length === 0 || sol.recordset[0].tipo_usuario !== "Root")
    fail("Solo el usuario Root puede eliminar usuarios.", 403);
  if (await esUnicoRoot(dni))
    fail("No se puede eliminar al único Root del sistema.", 400);
  const result = await db.request()
    .input("dni", sql.NVarChar(20), dni)
    .query(`UPDATE dbo.usuario SET estado = 0 WHERE dni = @dni AND estado = 1;`);
  return result.rowsAffected[0] > 0;
}

export async function login(nombre: string, password: string) {
  const db = await getPool();
  const result = await db.request()
    .input("nombre", sql.NVarChar(150), String(nombre ?? "").trim())
    .query(`SELECT dni, nombre, edad, tipo_usuario, telefono, residencia, correo, sexo, info_adicional, avatar, estado, password
            FROM dbo.usuario WHERE nombre = @nombre AND estado = 1;`);
  const u = result.recordset[0];
  if (!u || String(u.password) !== String(password ?? "")) return null;
  delete u.password;
  return u;
}

function fail(message: string, statusCode: number): never {
  const e = new Error(message) as any;
  e.statusCode = statusCode;
  throw e;
}
