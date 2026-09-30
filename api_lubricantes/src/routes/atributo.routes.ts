import { Router } from "express";
import multer from "multer";
import fs from "fs";
import { logosDir, subirLogo } from "../controllers/atributo.controller";
import * as controller from "../controllers/atributo.controller";

fs.mkdirSync(logosDir(), { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, logosDir()),
  filename: (_req, file, cb) => {
    const ext = file.originalname.substring(file.originalname.lastIndexOf(".")).toLowerCase() || ".png";
    cb(null, `lab-${Date.now()}${ext}`);
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
router.post("/:tabla/:id/logo", upload.single("logo"), subirLogo);
router.get("/:tabla", controller.listar);
router.post("/:tabla", controller.crear);
router.put("/:tabla/:id", controller.actualizar);
router.delete("/:tabla/:id", controller.eliminar);
export default router;
