import { Request, Response, NextFunction } from "express";
import * as service from "../services/venta.service";

export async function listar(req: Request, res: Response, next: NextFunction) {
  try {
    const q = String(req.query.q ?? "").trim();
    const data = await service.obtenerVentas(q || undefined);
    res.json({ ok: true, message: "Ventas obtenidas correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function resumen(req: Request, res: Response, next: NextFunction) {
  try {
    const dni = req.query.dni ? String(req.query.dni) : undefined;
    const data = await service.resumenVentas(dni);
    res.json({ ok: true, message: "Resumen obtenido correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function obtener(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.obtenerVentaPorCodigo(Number(req.params.codigo));
    if (!data) return res.status(404).json({ ok: false, message: "Venta no encontrada", data: null, errors: [] });
    res.json({ ok: true, message: "Venta obtenida correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function crear(req: Request, res: Response, next: NextFunction) {
  try {
    const data = await service.crearVenta(req.body);
    res.status(201).json({ ok: true, message: "Venta registrada correctamente", data, errors: [] });
  } catch (e) { next(e); }
}

export async function anular(req: Request, res: Response, next: NextFunction) {
  try {
    const ok = await service.anularVenta(Number(req.params.codigo));
    if (!ok) return res.status(404).json({ ok: false, message: "Venta no encontrada", data: null, errors: [] });
    res.json({ ok: true, message: "Venta anulada correctamente", data: null, errors: [] });
  } catch (e) { next(e); }
}
