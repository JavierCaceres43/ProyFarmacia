import path from "path";
import express from "express";
import cors from "cors";
import { env } from "./config/env";
import { testConnection } from "./config/database";
import routes from "./routes";
import { errorHandler } from "./middleware/errorHandler";

const app = express();
app.use(cors());
app.use(express.json());

// Interfaz web (carpeta /public). Debe ir antes de las rutas para servir index.html en "/".
app.use(express.static(path.join(__dirname, "..", "public")));

app.get("/api", (_req, res) => res.json({ ok:true, message:"API de Farmacia", data:{version:"2.0.0"}, errors:[] }));
app.get("/api/health", async (_req,res) => {
  try { await testConnection(); res.json({ok:true,message:"API y SQL Server disponibles",data:null,errors:[]}); }
  catch (e) { res.status(503).json({ok:false,message:"API disponible, pero no se pudo conectar a SQL Server",data:null,errors:[e instanceof Error ? e.message : String(e)]}); }
});
app.use("/api", routes);
app.use(errorHandler);

app.listen(env.port, () => console.log(`Interfaz y API en http://localhost:${env.port}`));
