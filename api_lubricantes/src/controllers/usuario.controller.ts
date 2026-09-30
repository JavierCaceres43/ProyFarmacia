import { Request, Response, NextFunction } from "express";
import * as service from "../services/usuario.service";
import fs from "fs";
import path from "path";

export async function listar(req: Request, res: Response, next: NextFunction) {
  try {
    const q = String(req.query.q ?? "").trim();
    const data = await service.obtenerUsuarios(q || undefined);
    res.json({ ok: true, message: "Usuarios obtenidos correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function obtener(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.obtenerUsuarioPorDni(String(req.params.dni));
    if (!data) return res.status(404).json({ ok: false, message: "Usuario no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Usuario obtenido correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function crear(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.crearUsuario(req.body);
    res.status(201).json({ ok: true, message: "Usuario creado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function actualizar(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.actualizarUsuario(String(req.params.dni), req.body);
    if (!data) return res.status(404).json({ ok: false, message: "Usuario no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Usuario actualizado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function cambiarTipo(req: Request, res: Response, next: NextFunction) {
  try {
    const solicitadoPor = (req.body as any)?.solicitado_por ?? req.query.solicitado_por;
    const data = await service.cambiarTipo(String(req.params.dni), String(req.body.sentido ?? ""), solicitadoPor);
    if (!data) return res.status(404).json({ ok: false, message: "Usuario no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Tipo de usuario actualizado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function subirAvatar(req: Request, res: Response, next: NextFunction) {
  try {
    const archivo = (req as any).file as { filename: string } | undefined;
    if (!archivo)
      return res.status(400).json({ ok: false, message: "Debe seleccionar un archivo de imagen", data: null, errors: [] });
    const data = await service.actualizarAvatar(String(req.params.dni), archivo.filename);
    if (!data) return res.status(404).json({ ok: false, message: "Usuario no encontrado", data: null, errors: [] });
    if (data.anterior && data.anterior !== archivo.filename) {
      try { await fs.promises.unlink(path.join(avatarsDir(), data.anterior)); }
      catch { /* ignorar: el archivo viejo puede no existir */ }
    }
    res.json({ ok: true, message: "Avatar actualizado correctamente", data: { dni: data.dni, avatar: data.avatar }, errors: [] });
  } catch (e) { next(e); }
}

export function avatarsDir() {
  return path.join(__dirname, "..", "..", "public", "avatar");
}

export async function eliminar(req: Request, res: Response, next: NextFunction) {
  try {
    const solicitadoPor = (req.body as any)?.solicitado_por ?? req.query.solicitado_por;
    const ok = await service.eliminarUsuario(String(req.params.dni), solicitadoPor);
    if (!ok) return res.status(404).json({ ok: false, message: "Usuario no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Usuario eliminado correctamente", data: null, errors: [] });
  } catch (e) { next(e); }
}

export async function login(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.login(req.body?.nombre, req.body?.password);
    if (!data) return res.status(401).json({ ok: false, message: "Nombre o contraseña incorrectos", data: null, errors: [] });
    res.json({ ok: true, message: "Sesión iniciada correctamente", data, errors: [] });
  } catch (e) { next(e); }
}
