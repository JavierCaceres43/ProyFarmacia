import { Router } from "express";
import * as controller from "../controllers/producto.controller";
const router = Router();
router.get("/", controller.listar);
router.get("/:id", controller.obtener);
router.post("/", controller.crear);
router.put("/:id", controller.actualizar);
router.delete("/:id", controller.eliminar);
export default router;
