import { Request, Response, NextFunction } from "express";
import * as service from "../services/atributo.service";
import fs from "fs";
import path from "path";

export async function listar(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.listar(String(req.params.tabla));
    res.json({ ok: true, message: "Atributos obtenidos correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function crear(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.crear(String(req.params.tabla), req.body?.nombre);
    res.status(201).json({ ok: true, message: "Atributo creado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function actualizar(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.actualizar(String(req.params.tabla), Number(req.params.id), req.body?.nombre);
    if (!data) return res.status(404).json({ ok: false, message: "Atributo no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Atributo actualizado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function subirLogo(req: Request, res: Response, next: NextFunction) {
  try {
    if (String(req.params.tabla).toLowerCase() !== "laboratorio")
      return res.status(400).json({ ok: false, message: "Solo laboratorio admite logo", data: null, errors: [] });
    const archivo = (req as any).file as { filename: string } | undefined;
    if (!archivo)
      return res.status(400).json({ ok: false, message: "Debe seleccionar un archivo de imagen", data: null, errors: [] });
    const data = await service.actualizarLogo(Number(req.params.id), archivo.filename);
    if (!data) return res.status(404).json({ ok: false, message: "Atributo no encontrado", data: null, errors: [] });
    if (data.anterior && data.anterior !== archivo.filename) {
      try { await fs.promises.unlink(path.join(logosDir(), data.anterior)); }
      catch { /* ignorar: el archivo viejo puede no existir */ }
    }
    res.json({ ok: true, message: "Logo actualizado correctamente", data: { id: data.id, logo: data.logo }, errors: [] });
  } catch (e) { next(e); }
}

export function logosDir() {
  return path.join(__dirname, "..", "..", "public", "logos");
}

export async function eliminar(req: Request, res: Response, next: NextFunction) {
  try {
    const ok = await service.eliminar(String(req.params.tabla), Number(req.params.id));
    if (!ok) return res.status(404).json({ ok: false, message: "Atributo no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Atributo eliminado correctamente", data: null, errors: [] });
  } catch (e) { next(e); }
}
