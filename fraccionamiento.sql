-- ============================================================
-- VENTA FRACCIONADA: stock en unidades + precio por unidad.
-- Agrega unidades_por_envase y precio_unidad a dbo.producto
-- y fija los valores por caja de los productos bolivianos.
-- Uso: ejecutar completo (F5) una sola vez en farmacia_db.
-- ============================================================

USE farmacia_db;
GO

ALTER TABLE dbo.producto
ADD unidades_por_envase INT NOT NULL DEFAULT 1,
    precio_unidad DECIMAL(10,2) NULL;
GO

UPDATE dbo.producto SET precio_unidad = precio WHERE precio_unidad IS NULL;
GO

ALTER TABLE dbo.producto
ALTER COLUMN precio_unidad DECIMAL(10,2) NOT NULL;
GO

ALTER TABLE dbo.producto
ADD CONSTRAINT ck_producto_unidades CHECK (unidades_por_envase >= 1),
    CONSTRAINT ck_producto_precio_unidad CHECK (precio_unidad >= 0);
GO

-- Caja -> unidades (ids 5..20 según orden de inserción).
UPDATE dbo.producto SET unidades_por_envase = 100, precio_unidad = 0.35 WHERE id_producto = 5;
UPDATE dbo.producto SET unidades_por_envase = 50, precio_unidad = 0.57 WHERE id_producto = 6;
UPDATE dbo.producto SET unidades_por_envase = 21, precio_unidad = 1.52 WHERE id_producto = 7;
UPDATE dbo.producto SET unidades_por_envase = 30, precio_unidad = 0.83 WHERE id_producto = 8;
UPDATE dbo.producto SET unidades_por_envase = 30, precio_unidad = 0.60 WHERE id_producto = 9;
UPDATE dbo.producto SET unidades_por_envase = 5, precio_unidad = 4.40 WHERE id_producto = 10;
UPDATE dbo.producto SET unidades_por_envase = 60, precio_unidad = 0.50 WHERE id_producto = 11;
UPDATE dbo.producto SET unidades_por_envase = 30, precio_unidad = 0.92 WHERE id_producto = 12;
UPDATE dbo.producto SET unidades_por_envase = 10, precio_unidad = 1.50 WHERE id_producto = 14;
UPDATE dbo.producto SET unidades_por_envase = 2, precio_unidad = 6.00 WHERE id_producto = 16;
UPDATE dbo.producto SET unidades_por_envase = 100, precio_unidad = 0.20 WHERE id_producto = 17;
UPDATE dbo.producto SET unidades_por_envase = 2, precio_unidad = 8.00 WHERE id_producto = 18;
UPDATE dbo.producto SET unidades_por_envase = 12, precio_unidad = 1.75 WHERE id_producto = 19;
GO
