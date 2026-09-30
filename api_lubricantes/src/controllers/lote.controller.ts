import { Request, Response, NextFunction } from "express";
import * as service from "../services/lote.service";

export async function listar(req: Request, res: Response, next: NextFunction) {
  try {
    const q = String(req.query.q ?? "").trim();
    const data = await service.obtenerLotes(q || undefined);
    res.json({ ok: true, message: "Lotes obtenidos correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function obtener(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.obtenerLotePorCodigo(Number(req.params.codigo));
    if (!data) return res.status(404).json({ ok: false, message: "Lote no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Lote obtenido correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function crear(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.crearLote(req.body);
    res.status(201).json({ ok: true, message: "Lote creado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function actualizar(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.actualizarLote(Number(req.params.codigo), req.body);
    if (!data) return res.status(404).json({ ok: false, message: "Lote no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Lote actualizado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function eliminar(req: Request, res: Response, next: NextFunction) {
  try {
    const ok = await service.eliminarLote(Number(req.params.codigo));
    if (!ok) return res.status(404).json({ ok: false, message: "Lote no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Lote eliminado correctamente", data: null, errors: [] });
  } catch (e) { next(e); }
}
