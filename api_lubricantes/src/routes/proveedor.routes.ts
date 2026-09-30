import { Router } from "express";
import multer from "multer";
import fs from "fs";
import { avatarsDir, subirAvatar } from "../controllers/proveedor.controller";
import * as controller from "../controllers/proveedor.controller";

fs.mkdirSync(avatarsDir(), { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, avatarsDir()),
  filename: (_req, file, cb) => {
    const ext = file.originalname.substring(file.originalname.lastIndexOf(".")).toLowerCase() || ".png";
    cb(null, `prov-${Date.now()}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (/^image\/(png|jpe?g|gif|webp)$/.test(file.mimetype)) cb(null, true);
    else cb(new Error("Solo se permiten imágenes (png, jpg, gif, webp)."));
  }
});

const router = Router();
router.post("/:id/avatar", upload.single("avatar"), subirAvatar);
router.get("/", controller.listar);
router.get("/:id", controller.obtener);
router.post("/", controller.crear);
router.put("/:id", controller.actualizar);
router.delete("/:id", controller.eliminar);
export default router;
