import { Request, Response, NextFunction } from "express";
import * as service from "../services/proveedor.service";
import fs from "fs";
import path from "path";

export async function listar(req: Request, res: Response, next: NextFunction) {
  try {
    const q = String(req.query.q ?? "").trim();
    const data = await service.obtenerProveedores(q || undefined);
    res.json({ ok: true, message: "Proveedores obtenidos correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function obtener(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.obtenerProveedorPorId(Number(req.params.id));
    if (!data) return res.status(404).json({ ok: false, message: "Proveedor no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Proveedor obtenido correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function crear(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.crearProveedor(req.body);
    res.status(201).json({ ok: true, message: "Proveedor creado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function actualizar(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.actualizarProveedor(Number(req.params.id), req.body);
    if (!data) return res.status(404).json({ ok: false, message: "Proveedor no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Proveedor actualizado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function subirAvatar(req: Request, res: Response, next: NextFunction) {
  try {
    const archivo = (req as any).file as { filename: string } | undefined;
    if (!archivo)
      return res.status(400).json({ ok: false, message: "Debe seleccionar un archivo de imagen", data: null, errors: [] });
    const data = await service.actualizarAvatar(Number(req.params.id), archivo.filename);
    if (!data) return res.status(404).json({ ok: false, message: "Proveedor no encontrado", data: null, errors: [] });
    if (data.anterior && data.anterior !== archivo.filename) {
      try { await fs.promises.unlink(path.join(avatarsDir(), data.anterior)); }
      catch { /* ignorar: el archivo viejo puede no existir */ }
    }
    res.json({ ok: true, message: "Avatar actualizado correctamente", data: { id: data.id, avatar: data.avatar }, errors: [] });
  } catch (e) { next(e); }
}

export function avatarsDir() {
  return path.join(__dirname, "..", "..", "public", "avatar");
}

export async function eliminar(req: Request, res: Response, next: NextFunction) {
  try {
    const ok = await service.eliminarProveedor(Number(req.params.id));
    if (!ok) return res.status(404).json({ ok: false, message: "Proveedor no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Proveedor eliminado correctamente", data: null, errors: [] });
  } catch (e) { next(e); }
}
