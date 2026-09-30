import { Request, Response, NextFunction } from "express";
import path from "path";

export function compDir() {
  return path.join(__dirname, "..", "..", "public", "comprobantes");
}

export async function subir(req: Request, res: Response, next: NextFunction) {
  try {
    const archivo = (req as any).file as { filename: string } | undefined;
    if (!archivo)
      return res.status(400).json({ ok: false, message: "Debe seleccionar la imagen del comprobante", data: null, errors: [] });
    res.status(201).json({ ok: true, message: "Comprobante subido correctamente", data: { archivo: archivo.filename }, errors: [] });
  } catch (e) { next(e); }
}
