import { NextFunction, Request, Response } from "express";

export function errorHandler(err: any, _req: Request, res: Response, _next: NextFunction) {
  console.error(err);
  const status = Number(err?.statusCode ?? 500);
  res.status(status).json({
    ok: false,
    message: err?.message ?? "Error interno del servidor",
    data: null,
    errors: err?.errors ?? []
  });
}
