import { Router } from "express";
import multer from "multer";
import fs from "fs";
import { avatarsDir, subirAvatar } from "../controllers/usuario.controller";
import * as controller from "../controllers/usuario.controller";

fs.mkdirSync(avatarsDir(), { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, avatarsDir()),
  filename: (_req, file, cb) => {
    const ext = file.originalname.substring(file.originalname.lastIndexOf(".")).toLowerCase() || ".png";
    cb(null, `user-${Date.now()}${ext}`);
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
router.post("/login", controller.login);
router.post("/:dni/avatar", upload.single("avatar"), subirAvatar);
router.get("/", controller.listar);
router.get("/:dni", controller.obtener);
router.post("/", controller.crear);
router.put("/:dni/tipo", controller.cambiarTipo);
router.put("/:dni", controller.actualizar);
router.delete("/:dni", controller.eliminar);
export default router;
