import dotenv from "dotenv";
dotenv.config();

export const env = {
  port: Number(process.env.PORT ?? 3000),
  dbHost: process.env.DB_HOST ?? "localhost",
  dbPort: Number(process.env.DB_PORT ?? 1433),
  dbName: process.env.DB_NAME ?? "InventarioLubricantesDB",
  dbUser: process.env.DB_USER ?? "sa",
  dbPassword: process.env.DB_PASSWORD ?? "",
  trusted: process.env.DB_TRUSTED_CONNECTION === "true",
  trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE !== "false"
};
