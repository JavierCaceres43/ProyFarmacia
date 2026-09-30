-- ============================================================
-- BASE DE DATOS FARMACIA MAMAN - SQL SERVER (T-SQL)
-- Conversión de "Scripts_Base_Datos_Farmacia_Maman_PostgreSQL" (Scripts 1 al 9)
-- Requiere SQL Server 2016 SP1 o superior (CREATE OR ALTER, OPENJSON, THROW).
--
-- Uso: abrir en SSMS y ejecutar completo (F5).
-- Este script NO borra datos. Si necesitas empezar de cero, usa el
-- bloque opcional "REINICIO" que está comentado más abajo.
-- ============================================================

-- ============================================================
-- SCRIPT 1 - CREACIÓN DE LA BASE DE DATOS
-- ============================================================
USE master;
GO

IF DB_ID(N'farmacia_maman_db') IS NULL
    CREATE DATABASE farmacia_maman_db;
GO

USE farmacia_maman_db;
GO

/* ------------------------------------------------------------
   REINICIO OPCIONAL (BORRA TODAS LAS TABLAS Y DATOS)
   Quita los comentarios solo si quieres recrear todo desde cero.

DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'DROP PROCEDURE dbo.' + QUOTENAME(name) + N';' + CHAR(10)
FROM sys.procedures WHERE schema_id = SCHEMA_ID(N'dbo') AND name LIKE N'sp[_]%';
EXEC sys.sp_executesql @sql;
GO
DROP TABLE IF EXISTS dbo.detalle_venta;
DROP TABLE IF EXISTS dbo.venta;
DROP TABLE IF EXISTS dbo.movimiento_caja;
DROP TABLE IF EXISTS dbo.caja;
DROP TABLE IF EXISTS dbo.movimiento_inventario;
DROP TABLE IF EXISTS dbo.lote;
DROP TABLE IF EXISTS dbo.producto;
DROP TABLE IF EXISTS dbo.proveedor;
DROP TABLE IF EXISTS dbo.categoria;
DROP TABLE IF EXISTS dbo.usuario;
DROP TABLE IF EXISTS dbo.rol;
GO
------------------------------------------------------------ */

-- ============================================================
-- SCRIPT 2 - TABLAS, RESTRICCIONES E ÍNDICES
-- ============================================================

CREATE TABLE dbo.rol (
    id_rol INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(50) NOT NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_rol PRIMARY KEY (id_rol),
    CONSTRAINT uq_rol_nombre UNIQUE (nombre),
    CONSTRAINT ck_rol_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0)
);
GO

CREATE TABLE dbo.usuario (
    id_usuario INT IDENTITY(1,1) NOT NULL,
    id_rol INT NOT NULL,
    nombre_completo NVARCHAR(150) NOT NULL,
    usuario NVARCHAR(50) NOT NULL,
    contrasena NVARCHAR(255) NOT NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_usuario PRIMARY KEY (id_usuario),
    CONSTRAINT fk_usuario_rol
        FOREIGN KEY (id_rol) REFERENCES dbo.rol(id_rol),
    CONSTRAINT uq_usuario_usuario UNIQUE (usuario),
    CONSTRAINT ck_usuario_nombre CHECK (LEN(LTRIM(RTRIM(nombre_completo))) > 0),
    CONSTRAINT ck_usuario_usuario CHECK (LEN(LTRIM(RTRIM(usuario))) >= 3)
);
GO

CREATE TABLE dbo.categoria (
    id_categoria INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(100) NOT NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_categoria PRIMARY KEY (id_categoria),
    CONSTRAINT uq_categoria_nombre UNIQUE (nombre),
    CONSTRAINT ck_categoria_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0)
);
GO

CREATE TABLE dbo.proveedor (
    id_proveedor INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(150) NOT NULL,
    telefono NVARCHAR(30) NULL,
    direccion NVARCHAR(200) NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor),
    CONSTRAINT ck_proveedor_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0)
);
GO

CREATE TABLE dbo.producto (
    id_producto INT IDENTITY(1,1) NOT NULL,
    id_categoria INT NOT NULL,
    codigo NVARCHAR(50) NOT NULL,
    nombre NVARCHAR(150) NOT NULL,
    descripcion NVARCHAR(300) NULL,
    precio_venta DECIMAL(10,2) NOT NULL,
    unidad_medida NVARCHAR(50) NOT NULL,
    estado BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_producto PRIMARY KEY (id_producto),
    CONSTRAINT fk_producto_categoria
        FOREIGN KEY (id_categoria) REFERENCES dbo.categoria(id_categoria),
    CONSTRAINT uq_producto_codigo UNIQUE (codigo),
    CONSTRAINT ck_producto_codigo CHECK (LEN(LTRIM(RTRIM(codigo))) > 0),
    CONSTRAINT ck_producto_nombre CHECK (LEN(LTRIM(RTRIM(nombre))) > 0),
    CONSTRAINT ck_producto_precio CHECK (precio_venta >= 0),
    CONSTRAINT ck_producto_unidad CHECK (LEN(LTRIM(RTRIM(unidad_medida))) > 0)
);
GO

CREATE TABLE dbo.lote (
    id_lote INT IDENTITY(1,1) NOT NULL,
    id_producto INT NOT NULL,
    id_proveedor INT NOT NULL,
    numero_lote NVARCHAR(50) NOT NULL,
    cantidad INT NOT NULL,
    fecha_ingreso DATE NOT NULL DEFAULT (CONVERT(DATE, GETDATE())),
    fecha_vencimiento DATE NOT NULL,

    CONSTRAINT pk_lote PRIMARY KEY (id_lote),
    CONSTRAINT fk_lote_producto
        FOREIGN KEY (id_producto) REFERENCES dbo.producto(id_producto),
    CONSTRAINT fk_lote_proveedor
        FOREIGN KEY (id_proveedor) REFERENCES dbo.proveedor(id_proveedor),
    CONSTRAINT uq_lote_producto_numero UNIQUE (id_producto, numero_lote),
    CONSTRAINT ck_lote_cantidad CHECK (cantidad >= 0),
    CONSTRAINT ck_lote_fechas CHECK (fecha_vencimiento >= fecha_ingreso)
);
GO

CREATE TABLE dbo.movimiento_inventario (
    id_movimiento INT IDENTITY(1,1) NOT NULL,
    id_lote INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo_movimiento NVARCHAR(20) NOT NULL,
    cantidad INT NOT NULL,
    fecha DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
    motivo NVARCHAR(200) NULL,

    CONSTRAINT pk_movimiento_inventario PRIMARY KEY (id_movimiento),
    CONSTRAINT fk_movimiento_lote
        FOREIGN KEY (id_lote) REFERENCES dbo.lote(id_lote),
    CONSTRAINT fk_movimiento_usuario
        FOREIGN KEY (id_usuario) REFERENCES dbo.usuario(id_usuario),
    CONSTRAINT ck_movimiento_tipo
        CHECK (tipo_movimiento IN (N'ENTRADA', N'SALIDA', N'AJUSTE')),
    CONSTRAINT ck_movimiento_cantidad CHECK (cantidad > 0)
);
GO

CREATE TABLE dbo.caja (
    id_caja INT IDENTITY(1,1) NOT NULL,
    id_usuario INT NOT NULL,
    fecha_apertura DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
    fecha_cierre DATETIME2(3) NULL,
    monto_inicial DECIMAL(10,2) NOT NULL DEFAULT 0,
    monto_final DECIMAL(10,2) NULL,
    estado NVARCHAR(20) NOT NULL DEFAULT N'ABIERTA',

    CONSTRAINT pk_caja PRIMARY KEY (id_caja),
    CONSTRAINT fk_caja_usuario
        FOREIGN KEY (id_usuario) REFERENCES dbo.usuario(id_usuario),
    CONSTRAINT ck_caja_estado
        CHECK (estado IN (N'ABIERTA', N'CERRADA')),
    CONSTRAINT ck_caja_monto_inicial CHECK (monto_inicial >= 0),
    CONSTRAINT ck_caja_monto_final CHECK (monto_final IS NULL OR monto_final >= 0),
    CONSTRAINT ck_caja_fechas
        CHECK (fecha_cierre IS NULL OR fecha_cierre >= fecha_apertura),
    CONSTRAINT ck_caja_estado_fecha
        CHECK (
            (estado = N'ABIERTA' AND fecha_cierre IS NULL)
            OR
            (estado = N'CERRADA' AND fecha_cierre IS NOT NULL)
        )
);
GO

CREATE TABLE dbo.movimiento_caja (
    id_movimiento_caja INT IDENTITY(1,1) NOT NULL,
    id_caja INT NOT NULL,
    id_usuario INT NOT NULL,
    tipo_movimiento NVARCHAR(20) NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    motivo NVARCHAR(200) NOT NULL,
    fecha DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT pk_movimiento_caja PRIMARY KEY (id_movimiento_caja),
    CONSTRAINT fk_movimiento_caja_caja
        FOREIGN KEY (id_caja) REFERENCES dbo.caja(id_caja),
    CONSTRAINT fk_movimiento_caja_usuario
        FOREIGN KEY (id_usuario) REFERENCES dbo.usuario(id_usuario),
    CONSTRAINT ck_movimiento_caja_tipo
        CHECK (tipo_movimiento IN (N'INGRESO', N'EGRESO')),
    CONSTRAINT ck_movimiento_caja_monto CHECK (monto > 0)
);
GO

CREATE TABLE dbo.venta (
    id_venta INT IDENTITY(1,1) NOT NULL,
    id_usuario INT NOT NULL,
    id_caja INT NOT NULL,
    numero_comprobante NVARCHAR(50) NOT NULL,
    fecha DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
    total DECIMAL(10,2) NOT NULL DEFAULT 0,

    CONSTRAINT pk_venta PRIMARY KEY (id_venta),
    CONSTRAINT fk_venta_usuario
        FOREIGN KEY (id_usuario) REFERENCES dbo.usuario(id_usuario),
    CONSTRAINT fk_venta_caja
        FOREIGN KEY (id_caja) REFERENCES dbo.caja(id_caja),
    CONSTRAINT uq_venta_comprobante UNIQUE (numero_comprobante),
    CONSTRAINT ck_venta_total CHECK (total >= 0)
);
GO

CREATE TABLE dbo.detalle_venta (
    id_detalle INT IDENTITY(1,1) NOT NULL,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,

    CONSTRAINT pk_detalle_venta PRIMARY KEY (id_detalle),
    CONSTRAINT fk_detalle_venta_venta
        FOREIGN KEY (id_venta) REFERENCES dbo.venta(id_venta),
    CONSTRAINT fk_detalle_venta_producto
        FOREIGN KEY (id_producto) REFERENCES dbo.producto(id_producto),
    CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_precio CHECK (precio_unitario >= 0),
    CONSTRAINT ck_detalle_subtotal CHECK (subtotal >= 0)
);
GO

-- Índices para las principales FK y consultas.
CREATE INDEX ix_usuario_rol ON dbo.usuario(id_rol);
CREATE INDEX ix_producto_categoria ON dbo.producto(id_categoria);
CREATE INDEX ix_producto_estado ON dbo.producto(estado);
CREATE INDEX ix_lote_producto ON dbo.lote(id_producto);
CREATE INDEX ix_lote_proveedor ON dbo.lote(id_proveedor);
CREATE INDEX ix_lote_vencimiento ON dbo.lote(fecha_vencimiento);
CREATE INDEX ix_movimiento_inventario_lote ON dbo.movimiento_inventario(id_lote);
CREATE INDEX ix_movimiento_inventario_fecha ON dbo.movimiento_inventario(fecha);
CREATE INDEX ix_caja_usuario ON dbo.caja(id_usuario);
CREATE INDEX ix_movimiento_caja_caja ON dbo.movimiento_caja(id_caja);
CREATE INDEX ix_venta_usuario ON dbo.venta(id_usuario);
CREATE INDEX ix_venta_caja ON dbo.venta(id_caja);
CREATE INDEX ix_venta_fecha ON dbo.venta(fecha);
CREATE INDEX ix_detalle_venta_venta ON dbo.detalle_venta(id_venta);
CREATE INDEX ix_detalle_venta_producto ON dbo.detalle_venta(id_producto);
GO

-- Evita más de una caja abierta por usuario (índice filtrado).
CREATE UNIQUE INDEX uq_caja_usuario_abierta
ON dbo.caja(id_usuario)
WHERE estado = N'ABIERTA';
GO


-- ============================================================
-- SCRIPT 3 - PROCEDIMIENTOS CRUD PRINCIPALES
-- Las funciones "consultar" de PostgreSQL pasan a ser
-- procedimientos almacenados que devuelven un result set.
-- ============================================================

-- CATEGORÍAS
CREATE OR ALTER PROCEDURE dbo.sp_categoria_insertar
    @p_nombre NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.categoria(nombre) VALUES (LTRIM(RTRIM(@p_nombre)));
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_categoria_actualizar
    @p_id_categoria INT,
    @p_nombre NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.categoria
    SET nombre = LTRIM(RTRIM(@p_nombre))
    WHERE id_categoria = @p_id_categoria;

    IF @@ROWCOUNT = 0
        THROW 50001, N'La categoría no existe.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_categoria_consultar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.id_categoria, c.nombre, c.estado
    FROM dbo.categoria c
    ORDER BY c.nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_categoria_desactivar
    @p_id_categoria INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.categoria SET estado = 0
    WHERE id_categoria = @p_id_categoria;

    IF @@ROWCOUNT = 0
        THROW 50001, N'La categoría no existe.', 1;
END;
GO


-- PROVEEDORES
CREATE OR ALTER PROCEDURE dbo.sp_proveedor_insertar
    @p_nombre NVARCHAR(150),
    @p_telefono NVARCHAR(30) = NULL,
    @p_direccion NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.proveedor(nombre, telefono, direccion)
    VALUES (LTRIM(RTRIM(@p_nombre)), @p_telefono, @p_direccion);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_proveedor_actualizar
    @p_id_proveedor INT,
    @p_nombre NVARCHAR(150),
    @p_telefono NVARCHAR(30) = NULL,
    @p_direccion NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.proveedor
    SET nombre = LTRIM(RTRIM(@p_nombre)),
        telefono = @p_telefono,
        direccion = @p_direccion
    WHERE id_proveedor = @p_id_proveedor;

    IF @@ROWCOUNT = 0
        THROW 50001, N'El proveedor no existe.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_proveedor_consultar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.id_proveedor, p.nombre, p.telefono, p.direccion, p.estado
    FROM dbo.proveedor p
    ORDER BY p.nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_proveedor_desactivar
    @p_id_proveedor INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.proveedor SET estado = 0
    WHERE id_proveedor = @p_id_proveedor;

    IF @@ROWCOUNT = 0
        THROW 50001, N'El proveedor no existe.', 1;
END;
GO


-- PRODUCTOS
CREATE OR ALTER PROCEDURE dbo.sp_producto_insertar
    @p_id_categoria INT,
    @p_codigo NVARCHAR(50),
    @p_nombre NVARCHAR(150),
    @p_descripcion NVARCHAR(300),
    @p_precio_venta DECIMAL(10,2),
    @p_unidad_medida NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.categoria
        WHERE id_categoria = @p_id_categoria AND estado = 1
    )
        THROW 50001, N'La categoría no existe o está inactiva.', 1;

    INSERT INTO dbo.producto(
        id_categoria, codigo, nombre, descripcion,
        precio_venta, unidad_medida
    )
    VALUES (
        @p_id_categoria, LTRIM(RTRIM(@p_codigo)), LTRIM(RTRIM(@p_nombre)),
        @p_descripcion, @p_precio_venta, LTRIM(RTRIM(@p_unidad_medida))
    );
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_producto_actualizar
    @p_id_producto INT,
    @p_id_categoria INT,
    @p_codigo NVARCHAR(50),
    @p_nombre NVARCHAR(150),
    @p_descripcion NVARCHAR(300),
    @p_precio_venta DECIMAL(10,2),
    @p_unidad_medida NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.producto
    SET id_categoria = @p_id_categoria,
        codigo = LTRIM(RTRIM(@p_codigo)),
        nombre = LTRIM(RTRIM(@p_nombre)),
        descripcion = @p_descripcion,
        precio_venta = @p_precio_venta,
        unidad_medida = LTRIM(RTRIM(@p_unidad_medida))
    WHERE id_producto = @p_id_producto;

    IF @@ROWCOUNT = 0
        THROW 50001, N'El producto no existe.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_producto_consultar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT p.id_producto, p.codigo, p.nombre, c.nombre AS categoria,
           p.descripcion, p.precio_venta, p.unidad_medida, p.estado
    FROM dbo.producto p
    INNER JOIN dbo.categoria c ON c.id_categoria = p.id_categoria
    ORDER BY p.nombre;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_producto_desactivar
    @p_id_producto INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.producto SET estado = 0
    WHERE id_producto = @p_id_producto;

    IF @@ROWCOUNT = 0
        THROW 50001, N'El producto no existe.', 1;
END;
GO


-- USUARIOS
CREATE OR ALTER PROCEDURE dbo.sp_usuario_insertar
    @p_id_rol INT,
    @p_nombre_completo NVARCHAR(150),
    @p_usuario NVARCHAR(50),
    @p_contrasena NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.rol
        WHERE id_rol = @p_id_rol AND estado = 1
    )
        THROW 50001, N'El rol no existe o está inactivo.', 1;

    INSERT INTO dbo.usuario(id_rol, nombre_completo, usuario, contrasena)
    VALUES (
        @p_id_rol, LTRIM(RTRIM(@p_nombre_completo)),
        LTRIM(RTRIM(@p_usuario)), @p_contrasena
    );
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_actualizar
    @p_id_usuario INT,
    @p_id_rol INT,
    @p_nombre_completo NVARCHAR(150),
    @p_usuario NVARCHAR(50),
    @p_contrasena NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Si @p_contrasena es NULL se conserva la contraseña actual.
    UPDATE dbo.usuario
    SET id_rol = @p_id_rol,
        nombre_completo = LTRIM(RTRIM(@p_nombre_completo)),
        usuario = LTRIM(RTRIM(@p_usuario)),
        contrasena = COALESCE(@p_contrasena, contrasena)
    WHERE id_usuario = @p_id_usuario;

    IF @@ROWCOUNT = 0
        THROW 50001, N'El usuario no existe.', 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_consultar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.id_usuario, u.nombre_completo, u.usuario,
           r.nombre AS rol, u.estado
    FROM dbo.usuario u
    INNER JOIN dbo.rol r ON r.id_rol = u.id_rol
    ORDER BY u.nombre_completo;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_usuario_desactivar
    @p_id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.usuario SET estado = 0
    WHERE id_usuario = @p_id_usuario;

    IF @@ROWCOUNT = 0
        THROW 50001, N'El usuario no existe.', 1;
END;
GO


-- ============================================================
-- SCRIPT 4 - DESENCADENADORES
-- En SQL Server los triggers son por instrucción (no por fila):
-- se trabaja con las tablas virtuales inserted / deleted.
-- ============================================================

-- 1. Calcular automáticamente el subtotal.
CREATE OR ALTER TRIGGER dbo.trg_detalle_venta_subtotal
ON dbo.detalle_venta
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dv
    SET subtotal = dv.cantidad * dv.precio_unitario
    FROM dbo.detalle_venta dv
    INNER JOIN inserted i ON i.id_detalle = dv.id_detalle
    WHERE dv.subtotal <> dv.cantidad * dv.precio_unitario;
END;
GO

-- 2. Actualizar el total de la venta.
CREATE OR ALTER TRIGGER dbo.trg_detalle_venta_actualizar_total
ON dbo.detalle_venta
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE v
    SET total = ISNULL(
        (SELECT SUM(d.subtotal)
         FROM dbo.detalle_venta d
         WHERE d.id_venta = v.id_venta), 0)
    FROM dbo.venta v
    WHERE v.id_venta IN (
        SELECT id_venta FROM inserted
        UNION
        SELECT id_venta FROM deleted
    );
END;
GO

-- Orden de ejecución: primero el subtotal, luego el total de la venta.
EXEC sp_settriggerorder @triggername = N'dbo.trg_detalle_venta_subtotal',
     @order = N'First', @stmttype = N'INSERT';
EXEC sp_settriggerorder @triggername = N'dbo.trg_detalle_venta_subtotal',
     @order = N'First', @stmttype = N'UPDATE';
GO

-- 3. Validar que no se venda un producto inactivo.
CREATE OR ALTER TRIGGER dbo.trg_detalle_venta_producto_activo
ON dbo.detalle_venta
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN dbo.producto p ON p.id_producto = i.id_producto
        WHERE p.id_producto IS NULL OR p.estado = 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, N'El producto está inactivo o no existe.', 1;
    END
END;
GO

-- 4. Validar producto y proveedor activos en el lote.
CREATE OR ALTER TRIGGER dbo.trg_lote_validar_activos
ON dbo.lote
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN dbo.producto p ON p.id_producto = i.id_producto
        WHERE p.id_producto IS NULL OR p.estado = 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, N'El producto del lote está inactivo o no existe.', 1;
    END

    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN dbo.proveedor pr ON pr.id_proveedor = i.id_proveedor
        WHERE pr.id_proveedor IS NULL OR pr.estado = 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, N'El proveedor está inactivo o no existe.', 1;
    END
END;
GO


-- ============================================================
-- SCRIPT 5 - INVENTARIO
-- ============================================================

-- Registrar ingreso de un nuevo lote.
CREATE OR ALTER PROCEDURE dbo.sp_inventario_registrar_entrada
    @p_id_producto INT,
    @p_id_proveedor INT,
    @p_numero_lote NVARCHAR(50),
    @p_cantidad INT,
    @p_fecha_ingreso DATE,
    @p_fecha_vencimiento DATE,
    @p_id_usuario INT,
    @p_motivo NVARCHAR(200) = N'Ingreso de mercadería'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @id_lote INT;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.producto
        WHERE id_producto = @p_id_producto AND estado = 1
    )
        THROW 50001, N'El producto no existe o está inactivo.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.proveedor
        WHERE id_proveedor = @p_id_proveedor AND estado = 1
    )
        THROW 50001, N'El proveedor no existe o está inactivo.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.usuario
        WHERE id_usuario = @p_id_usuario AND estado = 1
    )
        THROW 50001, N'El usuario no existe o está inactivo.', 1;

    IF @p_cantidad <= 0
        THROW 50001, N'La cantidad debe ser mayor que cero.', 1;

    IF @p_fecha_vencimiento < @p_fecha_ingreso
        THROW 50001, N'La fecha de vencimiento no puede ser anterior al ingreso.', 1;

    BEGIN TRANSACTION;

    INSERT INTO dbo.lote(
        id_producto, id_proveedor, numero_lote, cantidad,
        fecha_ingreso, fecha_vencimiento
    )
    VALUES (
        @p_id_producto, @p_id_proveedor, @p_numero_lote, @p_cantidad,
        @p_fecha_ingreso, @p_fecha_vencimiento
    );

    SET @id_lote = SCOPE_IDENTITY();

    INSERT INTO dbo.movimiento_inventario(
        id_lote, id_usuario, tipo_movimiento, cantidad, fecha, motivo
    )
    VALUES (
        @id_lote, @p_id_usuario, N'ENTRADA',
        @p_cantidad, SYSDATETIME(), @p_motivo
    );

    COMMIT TRANSACTION;
END;
GO

-- Registrar un movimiento de inventario.
CREATE OR ALTER PROCEDURE dbo.sp_movimiento_inventario_registrar
    @p_id_lote INT,
    @p_id_usuario INT,
    @p_tipo_movimiento NVARCHAR(20),
    @p_cantidad INT,
    @p_motivo NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.lote WHERE id_lote = @p_id_lote)
        THROW 50001, N'El lote no existe.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.usuario
        WHERE id_usuario = @p_id_usuario AND estado = 1
    )
        THROW 50001, N'El usuario no existe o está inactivo.', 1;

    IF @p_tipo_movimiento NOT IN (N'ENTRADA', N'SALIDA', N'AJUSTE')
        THROW 50001, N'Tipo de movimiento no válido.', 1;

    IF @p_cantidad <= 0
        THROW 50001, N'La cantidad debe ser mayor que cero.', 1;

    INSERT INTO dbo.movimiento_inventario(
        id_lote, id_usuario, tipo_movimiento, cantidad, motivo
    )
    VALUES (
        @p_id_lote, @p_id_usuario, @p_tipo_movimiento,
        @p_cantidad, @p_motivo
    );
END;
GO

-- Consultar stock disponible.
CREATE OR ALTER PROCEDURE dbo.sp_inventario_consultar_stock
    @p_id_producto INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.id_producto,
        p.codigo,
        p.nombre,
        p.unidad_medida,
        CAST(COALESCE(SUM(
            CASE
                WHEN l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
                THEN l.cantidad
                ELSE 0
            END
        ), 0) AS BIGINT) AS stock_disponible
    FROM dbo.producto p
    LEFT JOIN dbo.lote l ON l.id_producto = p.id_producto
    WHERE p.estado = 1
      AND (@p_id_producto IS NULL OR p.id_producto = @p_id_producto)
    GROUP BY p.id_producto, p.codigo, p.nombre, p.unidad_medida
    ORDER BY p.nombre;
END;
GO

-- Consultar lotes de un producto.
CREATE OR ALTER PROCEDURE dbo.sp_inventario_consultar_lotes
    @p_id_producto INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.id_lote,
        p.codigo,
        p.nombre AS producto,
        pr.nombre AS proveedor,
        l.numero_lote,
        l.cantidad,
        l.fecha_ingreso,
        l.fecha_vencimiento,
        DATEDIFF(DAY, CAST(GETDATE() AS DATE), l.fecha_vencimiento) AS dias_para_vencer
    FROM dbo.lote l
    INNER JOIN dbo.producto p ON p.id_producto = l.id_producto
    INNER JOIN dbo.proveedor pr ON pr.id_proveedor = l.id_proveedor
    WHERE l.id_producto = @p_id_producto
    ORDER BY l.fecha_vencimiento;
END;
GO

-- Productos/lotes próximos a vencer.
CREATE OR ALTER PROCEDURE dbo.sp_inventario_productos_por_vencer
    @p_dias INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        l.id_lote,
        p.codigo,
        p.nombre AS producto,
        l.numero_lote,
        l.cantidad,
        l.fecha_vencimiento,
        DATEDIFF(DAY, CAST(GETDATE() AS DATE), l.fecha_vencimiento) AS dias_restantes
    FROM dbo.lote l
    INNER JOIN dbo.producto p ON p.id_producto = l.id_producto
    WHERE l.cantidad > 0
      AND l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
      AND l.fecha_vencimiento <= DATEADD(DAY, @p_dias, CAST(GETDATE() AS DATE))
    ORDER BY l.fecha_vencimiento;
END;
GO

-- ============================================================
-- SCRIPT 6 - VENTAS
-- ============================================================

-- Registrar una venta completa.
-- @p_detalles es un JSON (NVARCHAR(MAX)) con esta forma:
-- [
--   {"id_producto":1,"cantidad":2,"precio_unitario":25.50},
--   {"id_producto":2,"cantidad":1,"precio_unitario":15.00}
-- ]
CREATE OR ALTER PROCEDURE dbo.sp_venta_registrar
    @p_id_usuario INT,
    @p_id_caja INT,
    @p_numero_comprobante NVARCHAR(50),
    @p_detalles NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;   -- cualquier error revierte toda la venta

    DECLARE @id_venta INT,
            @id_producto INT,
            @cantidad INT,
            @precio DECIMAL(10,2),
            @restante INT,
            @id_lote INT,
            @cantidad_lote INT,
            @salida INT,
            @msg NVARCHAR(200);

    IF NOT EXISTS (
        SELECT 1 FROM dbo.usuario
        WHERE id_usuario = @p_id_usuario AND estado = 1
    )
        THROW 50001, N'El usuario no existe o está inactivo.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.caja
        WHERE id_caja = @p_id_caja AND estado = N'ABIERTA'
    )
        THROW 50001, N'La caja no existe o está cerrada.', 1;

    IF ISNULL(ISJSON(@p_detalles), 0) <> 1
        THROW 50001, N'El detalle de la venta no es un JSON válido.', 1;

    IF LEFT(LTRIM(@p_detalles), 1) <> N'['
       OR NOT EXISTS (SELECT 1 FROM OPENJSON(@p_detalles))
        THROW 50001, N'La venta debe contener al menos un detalle.', 1;

    BEGIN TRANSACTION;

    -- Registrar cabecera.
    INSERT INTO dbo.venta(id_usuario, id_caja, numero_comprobante, total)
    VALUES (@p_id_usuario, @p_id_caja, @p_numero_comprobante, 0);

    SET @id_venta = SCOPE_IDENTITY();

    -- Procesar cada producto.
    DECLARE cur_detalle CURSOR LOCAL STATIC FORWARD_ONLY READ_ONLY FOR
        SELECT id_producto, cantidad, precio_unitario
        FROM OPENJSON(@p_detalles)
        WITH (
            id_producto     INT           '$.id_producto',
            cantidad        INT           '$.cantidad',
            precio_unitario DECIMAL(10,2) '$.precio_unitario'
        );

    OPEN cur_detalle;
    FETCH NEXT FROM cur_detalle INTO @id_producto, @cantidad, @precio;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @cantidad IS NULL OR @cantidad <= 0
            THROW 50001, N'La cantidad debe ser mayor que cero.', 1;

        IF @precio IS NULL OR @precio < 0
            THROW 50001, N'El precio no puede ser negativo.', 1;

        IF NOT EXISTS (
            SELECT 1 FROM dbo.producto
            WHERE id_producto = @id_producto AND estado = 1
        )
        BEGIN
            SET @msg = CONCAT(N'El producto ', @id_producto, N' no existe o está inactivo.');
            THROW 50001, @msg, 1;
        END

        -- Validar stock total (solo lotes vigentes).
        IF (
            SELECT ISNULL(SUM(l.cantidad), 0)
            FROM dbo.lote l
            WHERE l.id_producto = @id_producto
              AND l.cantidad > 0
              AND l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
        ) < @cantidad
        BEGIN
            SET @msg = CONCAT(N'Stock insuficiente para el producto ', @id_producto, N'.');
            THROW 50001, @msg, 1;
        END

        -- Registrar detalle (el trigger actualiza el total de la venta).
        INSERT INTO dbo.detalle_venta(
            id_venta, id_producto, cantidad, precio_unitario, subtotal
        )
        VALUES (
            @id_venta, @id_producto, @cantidad, @precio, @cantidad * @precio
        );

        SET @restante = @cantidad;

        -- FEFO: primero el lote que vence primero.
        DECLARE cur_lote CURSOR LOCAL STATIC FORWARD_ONLY READ_ONLY FOR
            SELECT l.id_lote, l.cantidad
            FROM dbo.lote l WITH (UPDLOCK, ROWLOCK)
            WHERE l.id_producto = @id_producto
              AND l.cantidad > 0
              AND l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
            ORDER BY l.fecha_vencimiento, l.id_lote;

        OPEN cur_lote;
        FETCH NEXT FROM cur_lote INTO @id_lote, @cantidad_lote;

        WHILE @@FETCH_STATUS = 0 AND @restante > 0
        BEGIN
            SET @salida = CASE WHEN @restante < @cantidad_lote
                               THEN @restante ELSE @cantidad_lote END;

            UPDATE dbo.lote
            SET cantidad = cantidad - @salida
            WHERE id_lote = @id_lote;

            INSERT INTO dbo.movimiento_inventario(
                id_lote, id_usuario, tipo_movimiento, cantidad, motivo
            )
            VALUES (
                @id_lote, @p_id_usuario, N'SALIDA', @salida, N'Salida por venta'
            );

            SET @restante = @restante - @salida;

            FETCH NEXT FROM cur_lote INTO @id_lote, @cantidad_lote;
        END

        CLOSE cur_lote;
        DEALLOCATE cur_lote;

        IF @restante > 0
            THROW 50001, N'No se pudo completar el descuento del stock.', 1;

        FETCH NEXT FROM cur_detalle INTO @id_producto, @cantidad, @precio;
    END

    CLOSE cur_detalle;
    DEALLOCATE cur_detalle;

    COMMIT TRANSACTION;
END;
GO

-- Consultar ventas.
CREATE OR ALTER PROCEDURE dbo.sp_venta_consultar
    @p_id_venta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        v.id_venta,
        v.numero_comprobante,
        v.fecha,
        u.nombre_completo AS usuario,
        v.total
    FROM dbo.venta v
    INNER JOIN dbo.usuario u ON u.id_usuario = v.id_usuario
    WHERE @p_id_venta IS NULL OR v.id_venta = @p_id_venta
    ORDER BY v.fecha DESC;
END;
GO

-- Consultar detalle de una venta.
CREATE OR ALTER PROCEDURE dbo.sp_venta_consultar_detalle
    @p_id_venta INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dv.id_detalle,
        v.numero_comprobante,
        p.codigo,
        p.nombre AS producto,
        dv.cantidad,
        dv.precio_unitario,
        dv.subtotal
    FROM dbo.detalle_venta dv
    INNER JOIN dbo.venta v ON v.id_venta = dv.id_venta
    INNER JOIN dbo.producto p ON p.id_producto = dv.id_producto
    WHERE dv.id_venta = @p_id_venta
    ORDER BY dv.id_detalle;
END;
GO


-- ============================================================
-- SCRIPT 7 - CAJA
-- ============================================================

-- Abrir caja (devuelve el id de la caja creada).
CREATE OR ALTER PROCEDURE dbo.sp_caja_abrir
    @p_id_usuario INT,
    @p_monto_inicial DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.usuario
        WHERE id_usuario = @p_id_usuario AND estado = 1
    )
        THROW 50001, N'El usuario no existe o está inactivo.', 1;

    IF @p_monto_inicial < 0
        THROW 50001, N'El monto inicial no puede ser negativo.', 1;

    IF EXISTS (
        SELECT 1 FROM dbo.caja
        WHERE id_usuario = @p_id_usuario AND estado = N'ABIERTA'
    )
        THROW 50001, N'El usuario ya tiene una caja abierta.', 1;

    INSERT INTO dbo.caja(id_usuario, monto_inicial, estado)
    VALUES (@p_id_usuario, @p_monto_inicial, N'ABIERTA');

    SELECT SCOPE_IDENTITY() AS id_caja;
END;
GO

-- Registrar ingreso o egreso de caja.
CREATE OR ALTER PROCEDURE dbo.sp_caja_registrar_movimiento
    @p_id_caja INT,
    @p_id_usuario INT,
    @p_tipo_movimiento NVARCHAR(20),
    @p_monto DECIMAL(10,2),
    @p_motivo NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.caja
        WHERE id_caja = @p_id_caja AND estado = N'ABIERTA'
    )
        THROW 50001, N'La caja no existe o está cerrada.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.usuario
        WHERE id_usuario = @p_id_usuario AND estado = 1
    )
        THROW 50001, N'El usuario no existe o está inactivo.', 1;

    IF @p_tipo_movimiento NOT IN (N'INGRESO', N'EGRESO')
        THROW 50001, N'Tipo de movimiento no válido.', 1;

    IF @p_monto <= 0
        THROW 50001, N'El monto debe ser mayor que cero.', 1;

    INSERT INTO dbo.movimiento_caja(
        id_caja, id_usuario, tipo_movimiento, monto, motivo
    )
    VALUES (
        @p_id_caja, @p_id_usuario, @p_tipo_movimiento, @p_monto, @p_motivo
    );
END;
GO

-- Cerrar caja.
CREATE OR ALTER PROCEDURE dbo.sp_caja_cerrar
    @p_id_caja INT,
    @p_monto_final DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.caja
        WHERE id_caja = @p_id_caja AND estado = N'ABIERTA'
    )
        THROW 50001, N'La caja no existe o ya está cerrada.', 1;

    IF @p_monto_final < 0
        THROW 50001, N'El monto final no puede ser negativo.', 1;

    UPDATE dbo.caja
    SET fecha_cierre = SYSDATETIME(),
        monto_final = @p_monto_final,
        estado = N'CERRADA'
    WHERE id_caja = @p_id_caja;
END;
GO

-- Consultar cajas.
CREATE OR ALTER PROCEDURE dbo.sp_caja_consultar
    @p_id_caja INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.id_caja,
        u.nombre_completo AS usuario,
        c.fecha_apertura,
        c.fecha_cierre,
        c.monto_inicial,
        c.monto_final,
        c.estado
    FROM dbo.caja c
    INNER JOIN dbo.usuario u ON u.id_usuario = c.id_usuario
    WHERE @p_id_caja IS NULL OR c.id_caja = @p_id_caja
    ORDER BY c.fecha_apertura DESC;
END;
GO

-- Consultar movimientos de caja.
CREATE OR ALTER PROCEDURE dbo.sp_caja_consultar_movimientos
    @p_id_caja INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        mc.id_movimiento_caja,
        mc.tipo_movimiento,
        mc.monto,
        mc.motivo,
        mc.fecha,
        u.nombre_completo AS usuario
    FROM dbo.movimiento_caja mc
    INNER JOIN dbo.usuario u ON u.id_usuario = mc.id_usuario
    WHERE mc.id_caja = @p_id_caja
    ORDER BY mc.fecha;
END;
GO


-- ============================================================
-- SCRIPT 8 - REPORTES
-- ============================================================

-- Ventas por período.
CREATE OR ALTER PROCEDURE dbo.sp_reporte_ventas_periodo
    @p_fecha_inicio DATE,
    @p_fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        v.id_venta,
        v.numero_comprobante,
        v.fecha,
        u.nombre_completo AS usuario,
        v.total
    FROM dbo.venta v
    INNER JOIN dbo.usuario u ON u.id_usuario = v.id_usuario
    WHERE v.fecha >= @p_fecha_inicio
      AND v.fecha <  DATEADD(DAY, 1, @p_fecha_fin)
    ORDER BY v.fecha;
END;
GO

-- Resumen de ventas.
CREATE OR ALTER PROCEDURE dbo.sp_reporte_resumen_ventas
    @p_fecha_inicio DATE,
    @p_fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COUNT_BIG(*) AS cantidad_ventas,
        CAST(ISNULL(SUM(total), 0) AS DECIMAL(10,2)) AS total_vendido
    FROM dbo.venta
    WHERE fecha >= @p_fecha_inicio
      AND fecha <  DATEADD(DAY, 1, @p_fecha_fin);
END;
GO

-- Estado del inventario.
CREATE OR ALTER PROCEDURE dbo.sp_reporte_inventario
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.id_producto,
        p.codigo,
        p.nombre AS producto,
        c.nombre AS categoria,
        p.unidad_medida,
        CAST(ISNULL(SUM(
            CASE
                WHEN l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
                THEN l.cantidad
                ELSE 0
            END
        ), 0) AS BIGINT) AS stock_disponible
    FROM dbo.producto p
    INNER JOIN dbo.categoria c ON c.id_categoria = p.id_categoria
    LEFT JOIN dbo.lote l ON l.id_producto = p.id_producto
    WHERE p.estado = 1
    GROUP BY
        p.id_producto, p.codigo, p.nombre,
        c.nombre, p.unidad_medida
    ORDER BY p.nombre;
END;
GO

-- Productos próximos a vencer.
CREATE OR ALTER PROCEDURE dbo.sp_reporte_productos_por_vencer
    @p_dias INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.codigo,
        p.nombre AS producto,
        l.numero_lote,
        l.cantidad,
        l.fecha_vencimiento,
        DATEDIFF(DAY, CAST(GETDATE() AS DATE), l.fecha_vencimiento) AS dias_restantes
    FROM dbo.lote l
    INNER JOIN dbo.producto p ON p.id_producto = l.id_producto
    WHERE l.cantidad > 0
      AND l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
      AND l.fecha_vencimiento <= DATEADD(DAY, @p_dias, CAST(GETDATE() AS DATE))
    ORDER BY l.fecha_vencimiento;
END;
GO

-- Movimientos de inventario.
CREATE OR ALTER PROCEDURE dbo.sp_reporte_movimientos_inventario
    @p_fecha_inicio DATE = NULL,
    @p_fecha_fin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        mi.id_movimiento,
        p.codigo,
        p.nombre AS producto,
        l.numero_lote,
        mi.tipo_movimiento,
        mi.cantidad,
        mi.fecha,
        mi.motivo,
        u.nombre_completo AS usuario
    FROM dbo.movimiento_inventario mi
    INNER JOIN dbo.lote l ON l.id_lote = mi.id_lote
    INNER JOIN dbo.producto p ON p.id_producto = l.id_producto
    INNER JOIN dbo.usuario u ON u.id_usuario = mi.id_usuario
    WHERE (@p_fecha_inicio IS NULL OR mi.fecha >= @p_fecha_inicio)
      AND (@p_fecha_fin IS NULL OR mi.fecha < DATEADD(DAY, 1, @p_fecha_fin))
    ORDER BY mi.fecha DESC;
END;
GO


-- ============================================================
-- SCRIPT 9 - SEGURIDAD Y USUARIOS
-- La aplicación Laravel debe comparar la contraseña con un hash
-- seguro (Argon2id o bcrypt). Nunca guardar texto plano.
-- (sp_usuario_desactivar ya se creó en el Script 3; en el original
--  estaba duplicado con el mismo contenido.)
-- ============================================================

-- Consulta para inicio de sesión.
CREATE OR ALTER PROCEDURE dbo.sp_usuario_login
    @p_usuario NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.id_usuario,
        u.nombre_completo,
        u.usuario,
        u.contrasena,
        r.id_rol,
        r.nombre AS rol,
        u.estado
    FROM dbo.usuario u
    INNER JOIN dbo.rol r ON r.id_rol = u.id_rol
    WHERE u.usuario = @p_usuario
      AND u.estado = 1;
END;
GO

-- Cambiar contraseña.
CREATE OR ALTER PROCEDURE dbo.sp_usuario_cambiar_contrasena
    @p_id_usuario INT,
    @p_nueva_contrasena NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.usuario WHERE id_usuario = @p_id_usuario
    )
        THROW 50001, N'El usuario no existe.', 1;

    IF ISNULL(LEN(@p_nueva_contrasena), 0) < 8
        THROW 50001, N'La contraseña debe tener al menos 8 caracteres.', 1;

    UPDATE dbo.usuario
    SET contrasena = @p_nueva_contrasena
    WHERE id_usuario = @p_id_usuario;
END;
GO

-- Activar usuario.
CREATE OR ALTER PROCEDURE dbo.sp_usuario_activar
    @p_id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.usuario
    SET estado = 1
    WHERE id_usuario = @p_id_usuario;

    IF @@ROWCOUNT = 0
        THROW 50001, N'El usuario no existe.', 1;
END;
GO

-- Consultar usuarios por rol.
CREATE OR ALTER PROCEDURE dbo.sp_usuario_consultar_por_rol
    @p_id_rol INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.id_usuario,
        u.nombre_completo,
        u.usuario,
        r.nombre AS rol,
        u.estado
    FROM dbo.usuario u
    INNER JOIN dbo.rol r ON r.id_rol = u.id_rol
    WHERE @p_id_rol IS NULL OR u.id_rol = @p_id_rol
    ORDER BY u.nombre_completo;
END;
GO

-- Consultar un usuario por ID.
CREATE OR ALTER PROCEDURE dbo.sp_usuario_consultar_por_id
    @p_id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.id_usuario,
        u.nombre_completo,
        u.usuario,
        r.id_rol,
        r.nombre AS rol,
        u.estado
    FROM dbo.usuario u
    INNER JOIN dbo.rol r ON r.id_rol = u.id_rol
    WHERE u.id_usuario = @p_id_usuario;
END;
GO

-- Roles iniciales del sistema.
INSERT INTO dbo.rol(nombre)
SELECT v.nombre
FROM (VALUES (N'ADMINISTRADOR'), (N'PERSONAL_ATENCION')) AS v(nombre)
WHERE NOT EXISTS (SELECT 1 FROM dbo.rol r WHERE r.nombre = v.nombre);
GO
