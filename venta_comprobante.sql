-- ============================================================
-- Comprobante de pago QR por venta.
-- Agrega comprobante (nombre de archivo, opcional) a dbo.venta.
-- Uso: ejecutar completo (F5) una sola vez en farmacia_db.
-- ============================================================

USE farmacia_db;
GO

ALTER TABLE dbo.venta
ADD comprobante NVARCHAR(255) NULL;
GO
