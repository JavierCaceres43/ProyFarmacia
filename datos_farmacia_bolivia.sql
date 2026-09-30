-- ============================================================
-- DATOS DE FARMACIA BOLIVIANA para farmacia_db - SQL SERVER
-- Precios en Bolivianos (Bs). Direcciones y teléfonos de Bolivia
-- (La Paz, Santa Cruz, Cochabamba, Sucre). CI = Cédula de Identidad.
-- Usuarios nuevos: password = dni.
-- Uso: ejecutar completo (F5) o con el runner por lotes GO.
-- ============================================================

USE farmacia_db;
GO

-- Residencias bolivianas para los usuarios de las capturas.
UPDATE dbo.usuario SET residencia = N'Cochabamba/Cercado/Bolivia' WHERE dni = N'12345';
GO
UPDATE dbo.usuario SET residencia = N'Santa Cruz/Andrés Ibáñez/Bolivia' WHERE dni = N'67890';
GO

-- Laboratorios con presencia en Bolivia.
INSERT INTO dbo.laboratorio(nombre) VALUES
(N'INTI'),(N'Bagó'),(N'Vita'),(N'Cofar'),(N'Delta'),(N'Alcos');
GO
-- ids nuevos: 11=INTI, 12=Bagó, 13=Vita, 14=Cofar, 15=Delta, 16=Alcos

-- Presentaciones adicionales.
INSERT INTO dbo.presentacion(nombre) VALUES
(N'JARABE'),(N'GOTAS'),(N'AMPOLLA'),(N'SUPOSITORIO');
GO
-- ids nuevos: 13=JARABE, 14=GOTAS, 15=AMPOLLA, 16=SUPOSITORIO
-- (1=AEROSOL, 2=ANILLO, 3=CAPSULA, 4=CHAMPU, 5=CREMA, 6=EMULSION,
--  7=ENEMA, 8=ESPUMA, 9=GEL, 10=TABLETA, 11=INYECTABLE, 12=SUSPENSION)

-- Productos esenciales de farmacia (precios en Bs).
-- ids nuevos: 5 al 20 en orden de inserción.
INSERT INTO dbo.producto(nombre, concentracion, adicional, precio, unidades_por_envase, precio_unidad, id_laboratorio, id_tipo, id_presentacion) VALUES
(N'Paracetamol', N'500 mg', N'Caja x 100 Tabletas', 35.00, 100, 0.35, 11, 2, 10),
(N'Ibuprofeno', N'400 mg', N'Caja x 50 Cápsulas', 28.50, 50, 0.57, 12, 1, 3),
(N'Amoxicilina', N'500 mg', N'Caja x 21 Cápsulas', 32.00, 21, 1.52, 13, 2, 3),
(N'Omeprazol', N'20 mg', N'Caja x 30 Cápsulas', 25.00, 30, 0.83, 14, 2, 3),
(N'Loratadina', N'10 mg', N'Caja x 30 Tabletas', 18.00, 30, 0.60, 15, 2, 10),
(N'Diclofenaco', N'75 mg/3 mL', N'Caja x 5 Ampollas', 22.00, 5, 4.40, 16, 1, 15),
(N'Metformina', N'850 mg', N'Frasco x 60 Tabletas', 30.00, 60, 0.50, 11, 2, 10),
(N'Losartán', N'50 mg', N'Caja x 30 Tabletas', 27.50, 30, 0.92, 12, 1, 10),
(N'Ambroxol', N'15 mg/5 mL', N'Frasco x 120 mL Jarabe', 24.00, 1, 24.00, 13, 1, 13),
(N'Vitamina C', N'500 mg', N'Tubo x 10 Efervescentes', 15.00, 10, 1.50, 14, 1, 10),
(N'Clotrimazol', N'1%', N'Tubo x 20 g Crema', 19.50, 1, 19.50, 15, 2, 5),
(N'Albendazol', N'400 mg', N'Caja x 2 Tabletas Masticables', 12.00, 2, 6.00, 16, 2, 10),
(N'Aspirina', N'100 mg', N'Caja x 100 Tabletas', 20.00, 100, 0.20, 11, 1, 10),
(N'Fluconazol', N'150 mg', N'Caja x 2 Cápsulas', 16.00, 2, 8.00, 13, 2, 3),
(N'Glicerina', N'Adulto', N'Caja x 12 Supositorios', 21.00, 12, 1.75, 14, 1, 16),
(N'Paracetamol', N'120 mg/5 mL', N'Frasco x 90 mL Jarabe', 23.00, 1, 23.00, 11, 2, 13);
GO

-- Proveedores bolivianos (ids nuevos: 5 al 8 en orden).
INSERT INTO dbo.proveedor(nombre, telefono, correo, direccion, id_laboratorio) VALUES
(N'Droguería INTI', N'71712345', N'ventas@inti.bo', N'Av. América, Cochabamba', 11),
(N'Distribuidora San Juan', N'76754321', N'info@sanjuan.bo', N'Av. Grigotá, Santa Cruz', 12),
(N'Droguería La Paz', N'70198765', N'contacto@dlapaz.bo', N'Calle Comercio, La Paz', 13),
(N'Distribuidora Cochabamba', N'77456321', N'pedidos@dcbba.bo', N'Av. Heroínas, Cochabamba', 14);
GO

-- Usuarios bolivianos (password = dni).
INSERT INTO dbo.usuario(dni, nombre, edad, tipo_usuario, telefono, residencia, correo, sexo, password) VALUES
(N'45678901', N'María Fernández', 32, N'Técnico', N'75612348', N'La Paz/Murillo/Bolivia', N'maria.f@example.com', N'Femenino', N'45678901'),
(N'87654321', N'Carlos Mendoza', 41, N'Administrador', N'74369852', N'Sucre/Oropeza/Bolivia', N'carlos.m@example.com', N'Masculino', N'87654321');
GO

-- Lotes: mezcla de vencidos (rojo), por vencer <150 días (amarillo)
-- y vigentes (verde). id_producto 5..20, id_proveedor 5..8.
INSERT INTO dbo.lote(id_producto, id_proveedor, stock, fecha_vencimiento) VALUES
(5, 5, 120, DATEADD(DAY, 300, CAST(GETDATE() AS DATE))),
(5, 8, 30,  DATEADD(DAY, -15, CAST(GETDATE() AS DATE))),
(6, 6, 80,  DATEADD(DAY, 60,  CAST(GETDATE() AS DATE))),
(6, 7, 25,  DATEADD(DAY, -40, CAST(GETDATE() AS DATE))),
(7, 5, 90,  DATEADD(DAY, 200, CAST(GETDATE() AS DATE))),
(8, 6, 100, DATEADD(DAY, 90,  CAST(GETDATE() AS DATE))),
(9, 7, 150, DATEADD(DAY, 400, CAST(GETDATE() AS DATE))),
(10, 5, 60, DATEADD(DAY, 45,  CAST(GETDATE() AS DATE))),
(11, 8, 110, DATEADD(DAY, 250, CAST(GETDATE() AS DATE))),
(12, 6, 70, DATEADD(DAY, 120, CAST(GETDATE() AS DATE))),
(13, 7, 85, DATEADD(DAY, 180, CAST(GETDATE() AS DATE))),
(14, 5, 200, DATEADD(DAY, 30,  CAST(GETDATE() AS DATE))),
(15, 8, 40, DATEADD(DAY, 220, CAST(GETDATE() AS DATE))),
(16, 6, 95, DATEADD(DAY, 75,  CAST(GETDATE() AS DATE))),
(17, 5, 130, DATEADD(DAY, 320, CAST(GETDATE() AS DATE))),
(18, 7, 55, DATEADD(DAY, 55,  CAST(GETDATE() AS DATE))),
(19, 8, 35, DATEADD(DAY, 140, CAST(GETDATE() AS DATE))),
(20, 6, 75, DATEADD(DAY, 110, CAST(GETDATE() AS DATE)));
GO
