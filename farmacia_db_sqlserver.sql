-- ============================================================
-- BASE DE DATOS FARMACIA_DB - SQL SERVER (T-SQL)
-- Esquema diseñado conforme a la interfaz web del sistema
-- ("Sistema Farmacia - interfaz reconstruida").
-- Tablas: laboratorio, tipo, presentacion, producto, proveedor,
--         lote, usuario, venta, detalle_venta.
--
-- Uso: abrir en SSMS y ejecutar completo (F5).
-- Usuarios semilla: password = dni (ej. Root dni 12345, pass 12345).
-- ============================================================

USE master;
GO

IF DB_ID(N'farmacia_db') IS NULL
    CREATE DATABASE farmacia_db;
GO

USE farmacia_db;
GO

-- ============================================================
-- TABLAS MAESTRAS DE ATRIBUTOS
-- ============================================================

CREATE TABLE dbo.laboratorio (
    id_laboratorio INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(100) NOT NULL,
    logo NVARCHAR(255) NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_laboratorio PRIMARY KEY (id_laboratorio),
    CONSTRAINT uq_laboratorio_nombre UNIQUE (nombre),
    CONSTRAINT ck_laboratorio_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0)
);
GO

CREATE TABLE dbo.tipo (
    id_tipo INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(50) NOT NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_tipo PRIMARY KEY (id_tipo),
    CONSTRAINT uq_tipo_nombre UNIQUE (nombre),
    CONSTRAINT ck_tipo_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0)
);
GO

CREATE TABLE dbo.presentacion (
    id_presentacion INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(50) NOT NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_presentacion PRIMARY KEY (id_presentacion),
    CONSTRAINT uq_presentacion_nombre UNIQUE (nombre),
    CONSTRAINT ck_presentacion_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0)
);
GO

-- ============================================================
-- PRODUCTO (con concentracion / adicional / avatar + 3 FK)
-- ============================================================

CREATE TABLE dbo.producto (
    id_producto INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(150) NOT NULL,
    concentracion NVARCHAR(100) NULL,
    adicional NVARCHAR(200) NULL,
    precio DECIMAL(10,2) NOT NULL,
    unidades_por_envase INT NOT NULL DEFAULT 1,
    precio_unidad DECIMAL(10,2) NOT NULL,
    avatar NVARCHAR(255) NULL,
    id_laboratorio INT NOT NULL,
    id_tipo INT NOT NULL,
    id_presentacion INT NOT NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_producto PRIMARY KEY (id_producto),
    CONSTRAINT fk_producto_laboratorio
        FOREIGN KEY (id_laboratorio) REFERENCES dbo.laboratorio(id_laboratorio),
    CONSTRAINT fk_producto_tipo
        FOREIGN KEY (id_tipo) REFERENCES dbo.tipo(id_tipo),
    CONSTRAINT fk_producto_presentacion
        FOREIGN KEY (id_presentacion) REFERENCES dbo.presentacion(id_presentacion),
    CONSTRAINT ck_producto_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0),
    CONSTRAINT ck_producto_precio CHECK (precio >= 0),
    CONSTRAINT ck_producto_unidades CHECK (unidades_por_envase >= 1),
    CONSTRAINT ck_producto_precio_unidad CHECK (precio_unidad >= 0)
);
GO

-- ============================================================
-- PROVEEDOR
-- ============================================================

CREATE TABLE dbo.proveedor (
    id_proveedor INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(150) NOT NULL,
    telefono NVARCHAR(30) NULL,
    correo NVARCHAR(150) NULL,
    direccion NVARCHAR(200) NULL,
    avatar NVARCHAR(255) NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor),
    CONSTRAINT ck_proveedor_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0)
);
GO

-- ============================================================
-- LOTE (codigo PK, stock, vencimiento)
-- ============================================================

CREATE TABLE dbo.lote (
    codigo INT IDENTITY(1,1) NOT NULL,
    id_producto INT NOT NULL,
    id_proveedor INT NOT NULL,
    stock INT NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_lote PRIMARY KEY (codigo),
    CONSTRAINT fk_lote_producto
        FOREIGN KEY (id_producto) REFERENCES dbo.producto(id_producto),
    CONSTRAINT fk_lote_proveedor
        FOREIGN KEY (id_proveedor) REFERENCES dbo.proveedor(id_proveedor),
    CONSTRAINT ck_lote_stock CHECK (stock >= 0)
);
GO

-- ============================================================
-- USUARIO (dni como clave primaria)
-- tipo_usuario: Root / Administrador / Técnico
-- ============================================================

CREATE TABLE dbo.usuario (
    dni NVARCHAR(20) NOT NULL,
    nombre NVARCHAR(150) NOT NULL,
    edad INT NULL,
    tipo_usuario NVARCHAR(20) NOT NULL DEFAULT N'Técnico',
    telefono NVARCHAR(30) NULL,
    residencia NVARCHAR(200) NULL,
    correo NVARCHAR(150) NULL,
    sexo NVARCHAR(20) NULL,
    info_adicional NVARCHAR(300) NULL,
    avatar NVARCHAR(255) NULL,
    password NVARCHAR(255) NOT NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_usuario PRIMARY KEY (dni),
    CONSTRAINT uq_usuario_nombre UNIQUE (nombre),
    CONSTRAINT ck_usuario_tipo
        CHECK (tipo_usuario IN (N'Root', N'Administrador', N'Técnico')),
    CONSTRAINT ck_usuario_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0),
    CONSTRAINT ck_usuario_edad CHECK (edad IS NULL OR edad >= 0)
);
GO

-- ============================================================
-- VENTA + DETALLE (total con IGV 18% incluido)
-- ============================================================

CREATE TABLE dbo.venta (
    codigo INT IDENTITY(1,1) NOT NULL,
    fecha DATETIME2(3) NOT NULL DEFAULT (DATEADD(HOUR, -4, SYSUTCDATETIME())),
    cliente NVARCHAR(150) NOT NULL,
    dni_cliente NVARCHAR(20) NULL,
    total DECIMAL(10,2) NOT NULL,
    usuario_dni NVARCHAR(20) NOT NULL,
    estado BIT NOT NULL DEFAULT 1, -- 1 vigente, 0 anulada

    CONSTRAINT pk_venta PRIMARY KEY (codigo),
    CONSTRAINT fk_venta_usuario
        FOREIGN KEY (usuario_dni) REFERENCES dbo.usuario(dni),
    CONSTRAINT ck_venta_total CHECK (total >= 0)
);
GO

CREATE TABLE dbo.detalle_venta (
    id_detalle INT IDENTITY(1,1) NOT NULL,
    venta_codigo INT NOT NULL,
    lote_codigo INT NOT NULL,
    cantidad INT NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,

    CONSTRAINT pk_detalle_venta PRIMARY KEY (id_detalle),
    CONSTRAINT fk_detalle_venta_venta
        FOREIGN KEY (venta_codigo) REFERENCES dbo.venta(codigo),
    CONSTRAINT fk_detalle_venta_lote
        FOREIGN KEY (lote_codigo) REFERENCES dbo.lote(codigo),
    CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_precio CHECK (precio >= 0),
    CONSTRAINT ck_detalle_subtotal CHECK (subtotal >= 0)
);
GO

-- Índices para FK y búsquedas.
CREATE INDEX ix_producto_laboratorio ON dbo.producto(id_laboratorio);
CREATE INDEX ix_producto_tipo ON dbo.producto(id_tipo);
CREATE INDEX ix_producto_presentacion ON dbo.producto(id_presentacion);
CREATE INDEX ix_producto_estado ON dbo.producto(estado);
CREATE INDEX ix_lote_producto ON dbo.lote(id_producto);
CREATE INDEX ix_lote_proveedor ON dbo.lote(id_proveedor);
CREATE INDEX ix_lote_vencimiento ON dbo.lote(fecha_vencimiento);
CREATE INDEX ix_venta_usuario ON dbo.venta(usuario_dni);
CREATE INDEX ix_venta_fecha ON dbo.venta(fecha);
CREATE INDEX ix_detalle_venta_venta ON dbo.detalle_venta(venta_codigo);
CREATE INDEX ix_detalle_venta_lote ON dbo.detalle_venta(lote_codigo);
GO

-- ============================================================
-- DATOS SEMILLA (los mismos de las capturas de la interfaz)
-- ============================================================

INSERT INTO dbo.laboratorio(nombre) VALUES
(N'PORTUGAL'),(N'Bois'),(N'Desconocido'),(N'A & C MARVEL'),
(N'A. MENARINI'),(N'ABBA S.A.C.'),(N'ABBOTT'),
(N'IQ FARMA'),(N'FARMINDUSTRIA'),(N'MEDIFARMA');
GO

INSERT INTO dbo.tipo(nombre) VALUES
(N'Comercial'),(N'Generico'),(N'Regalos'),(N'Joyeria');
GO

INSERT INTO dbo.presentacion(nombre) VALUES
(N'AEROSOL'),(N'ANILLO'),(N'CAPSULA'),(N'CHAMPU'),(N'CREMA'),
(N'EMULSION'),(N'ENEMA'),(N'ESPUMA'),(N'GEL'),
(N'TABLETA'),(N'INYECTABLE'),(N'SUSPENSION');
GO

-- Productos de las capturas.
-- laboratorio: 8=IQ FARMA, 9=FARMINDUSTRIA, 10=MEDIFARMA
-- tipo: 1=Comercial | presentacion: 10=TABLETA, 11=INYECTABLE, 12=SUSPENSION
INSERT INTO dbo.producto(nombre, concentracion, adicional, precio, unidades_por_envase, precio_unidad, id_laboratorio, id_tipo, id_presentacion) VALUES
(N'A FOLIC', N'0.5 mg', N'Caja Envase Blister Tabletas', 1.50, 1, 1.50, 8, 1, 10),
(N'AB AMBROMOX', N'600 mg', N'Caja Vial', 2.00, 1, 2.00, 9, 1, 11),
(N'AB AMBROMOX', N'1 200 mg', N'Vial + Accesorios', 1.00, 1, 1.00, 9, 1, 11),
(N'AB MOKS', N'250 mg + 15 mg/5 mL', N'Frasco X 60 mL', 1.00, 1, 1.00, 10, 1, 12);
GO

-- Proveedores de las capturas.
INSERT INTO dbo.proveedor(nombre, telefono, correo, direccion) VALUES
(N'd', N'232', NULL, N'23'),
(N'juan diego23aaaa', N'2147483647', NULL, N'fasfasef'),
(N'distribuidora y droguería san carlos2', N'412341234', NULL, N'fasdfasdf'),
(N'juan diego2', N'2147483647', NULL, N'fasefasef');
GO

-- Usuarios de las capturas (password = dni).
-- 'admin' es el usuario padre del sistema (Root): administra a todos.
INSERT INTO dbo.usuario(dni, nombre, edad, tipo_usuario, residencia, password) VALUES
(N'admin', N'admin', NULL, N'Root', NULL, N'admin'),
(N'12345', N'Juan diego Polo Cosme', 26, N'Administrador', N'Trujillo/Libertad/Perú', N'12345'),
(N'67890', N'fernando salazar chiroque', 20, N'Administrador', N'santiago de chile', N'67890'),
(N'22232', N'juan eder polo cosme', 29, N'Técnico', NULL, N'22232'),
(N'20412154', N'312321 asdas', 0, N'Técnico', NULL, N'20412154');
GO

-- Lotes de las capturas (vencimientos relativos a hoy para demo).
-- id_producto: 1=A FOLIC, 2=AMBROMOX 600, 4=AB MOKS
-- id_proveedor: 1=d, 2=juan diego23aaaa, 3=distribuidora, 4=juan diego2
INSERT INTO dbo.lote(id_producto, id_proveedor, stock, fecha_vencimiento) VALUES
(1, 3, 10, DATEADD(DAY, 180, CAST(GETDATE() AS DATE))),
(1, 1, 2,  DATEADD(DAY, -29, CAST(GETDATE() AS DATE))),
(2, 1, 685, DATEADD(DAY, 1,  CAST(GETDATE() AS DATE))),
(2, 1, 2,  DATEADD(DAY, -29, CAST(GETDATE() AS DATE))),
(4, 2, 9,  DATEADD(DAY, 76, CAST(GETDATE() AS DATE))),
(4, 4, 7,  DATEADD(DAY, 22, CAST(GETDATE() AS DATE)));
GO

-- Ventas de las capturas (totales = suma de subtotales).
INSERT INTO dbo.venta(fecha, cliente, dni_cliente, total, usuario_dni) VALUES
('2019-01-08 12:50:10', N'ee', N'0', 3.50, N'20412154'),
('2019-02-08 15:30:50', N'segundo rojas', N'23423423', 4.50, N'12345'),
('2019-03-09 12:32:16', N'Fernando Robles', N'342324', 21.00, N'12345'),
('2020-07-29 13:52:17', N'fernando', N'0', 4.50, N'12345'),
(SYSDATETIME(), N'cliente demo', N'99999999', 15.00, N'12345');
GO

-- Detalle (codigos de venta 1..5 y de lote 1..6 según orden de inserción).
INSERT INTO dbo.detalle_venta(venta_codigo, lote_codigo, cantidad, precio, subtotal) VALUES
(1, 2, 1, 2.00, 2.00),
(1, 1, 1, 1.50, 1.50),
(2, 1, 3, 1.50, 4.50),
(3, 3, 10, 2.00, 20.00),
(3, 6, 1, 1.00, 1.00),
(4, 1, 1, 1.50, 1.50),
(4, 4, 1, 2.00, 2.00),
(4, 6, 1, 1.00, 1.00),
(5, 5, 15, 1.00, 15.00);
GO
