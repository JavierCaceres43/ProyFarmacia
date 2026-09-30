import { Request, Response, NextFunction } from "express";
import * as service from "../services/usuario.service";

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
    const data = await service.cambiarTipo(String(req.params.dni), String(req.body.sentido ?? ""));
    if (!data) return res.status(404).json({ ok: false, message: "Usuario no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Tipo de usuario actualizado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function eliminar(req: Request, res: Response, next: NextFunction) {
  try {
    const ok = await service.eliminarUsuario(String(req.params.dni));
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
