import sql from "mssql";
import { env } from "./env";

let pool: sql.ConnectionPool | null = null;

export async function getPool() {
  if (pool?.connected) return pool;

  // Si quedó un pool en mal estado, ciérralo antes de reconectar
  if (pool) {
    try { await pool.close(); } catch { /* ignorar */ }
    pool = null;
  }

  // Autenticación de SQL Server (usuario sa + contraseña), igual que en SSMS
  const config: sql.config = {
    server: env.dbHost,
    port: env.dbPort,
    database: env.dbName,
    user: env.dbUser,
    password: env.dbPassword,
    options: {
      encrypt: false,
      trustServerCertificate: env.trustServerCertificate,
      enableArithAbort: true
    },
    connectionTimeout: 15000,
    requestTimeout: 15000
  };

  pool = await new sql.ConnectionPool(config).connect();
  return pool;
}

export async function testConnection() {
  const db = await getPool();
  await db.request().query("SELECT 1 AS ok");
}
