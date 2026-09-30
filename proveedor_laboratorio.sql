-- ============================================================
-- Laboratorio que distribuye cada proveedor.
-- Agrega id_laboratorio (opcional) a dbo.proveedor y asigna
-- los laboratorios a los proveedores bolivianos (ids 5..8).
-- Uso: ejecutar completo (F5) una sola vez en farmacia_db.
-- ============================================================

USE farmacia_db;
GO

ALTER TABLE dbo.proveedor
ADD id_laboratorio INT NULL;
GO

ALTER TABLE dbo.proveedor
ADD CONSTRAINT fk_proveedor_laboratorio
    FOREIGN KEY (id_laboratorio) REFERENCES dbo.laboratorio(id_laboratorio);
GO

UPDATE dbo.proveedor SET id_laboratorio = 11 WHERE id_proveedor = 5;
UPDATE dbo.proveedor SET id_laboratorio = 12 WHERE id_proveedor = 6;
UPDATE dbo.proveedor SET id_laboratorio = 13 WHERE id_proveedor = 7;
UPDATE dbo.proveedor SET id_laboratorio = 14 WHERE id_proveedor = 8;
GO
