import { Request, Response, NextFunction } from "express";
import * as service from "../services/producto.service";

export async function listar(req: Request, res: Response, next: NextFunction) {
  try {
    const q = String(req.query.q ?? "").trim();
    const data = await service.obtenerProductos(q || undefined);
    res.json({ ok: true, message: "Productos obtenidos correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function obtener(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.obtenerProductoPorId(Number(req.params.id));
    if (!data) return res.status(404).json({ ok: false, message: "Producto no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Producto obtenido correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function crear(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.crearProducto(req.body);
    res.status(201).json({ ok: true, message: "Producto creado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function actualizar(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.actualizarProducto(Number(req.params.id), req.body);
    if (!data) return res.status(404).json({ ok: false, message: "Producto no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Producto actualizado correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function eliminar(req: Request, res: Response, next: NextFunction) {
  try {
    const ok = await service.desactivarProducto(Number(req.params.id));
    if (!ok) return res.status(404).json({ ok: false, message: "Producto no encontrado", data: null, errors: [] });
    res.json({ ok: true, message: "Producto desactivado correctamente", data: null, errors: [] });
  } catch (e) { next(e); }
}
