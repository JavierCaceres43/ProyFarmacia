import { Router } from "express";
import * as controller from "../controllers/lote.controller";
const router = Router();
router.get("/", controller.listar);
router.get("/:codigo", controller.obtener);
router.post("/", controller.crear);
router.put("/:codigo", controller.actualizar);
router.delete("/:codigo", controller.eliminar);
export default router;
