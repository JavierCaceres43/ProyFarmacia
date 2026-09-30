import { Router } from "express";
import multer from "multer";
import fs from "fs";
import { compDir, subir } from "../controllers/comprobante.controller";

fs.mkdirSync(compDir(), { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, compDir()),
  filename: (_req, file, cb) => {
    const ext = file.originalname.substring(file.originalname.lastIndexOf(".")).toLowerCase() || ".png";
    cb(null, `comp-${Date.now()}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (/^image\/(png|jpe?g|gif|webp)$/.test(file.mimetype)) cb(null, true);
    else cb(new Error("Solo se permiten imágenes (png, jpg, gif, webp)."));
  }
});

const router = Router();
router.post("/", upload.single("comprobante"), subir);
export default router;
