import { Router } from "express";
import * as controller from "../controllers/venta.controller";
const router = Router();
router.get("/resumen", controller.resumen);
router.get("/", controller.listar);
router.get("/:codigo", controller.obtener);
router.post("/", controller.crear);
router.delete("/:codigo", controller.anular);
export default router;
