-- ============================================================
-- Renombra el tipo "Técnico" a "Encargado".
-- Uso: ejecutar completo (F5) una sola vez en farmacia_db.
-- ============================================================

USE farmacia_db;
GO

ALTER TABLE dbo.usuario DROP CONSTRAINT ck_usuario_tipo;
GO

UPDATE dbo.usuario SET tipo_usuario = N'Encargado' WHERE tipo_usuario = N'Técnico';
GO

ALTER TABLE dbo.usuario
ADD CONSTRAINT ck_usuario_tipo
    CHECK (tipo_usuario IN (N'Root', N'Administrador', N'Encargado'));
GO

DECLARE @df NVARCHAR(200);
SELECT @df = dc.name
FROM sys.default_constraints dc
INNER JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE dc.parent_object_id = OBJECT_ID(N'dbo.usuario') AND c.name = N'tipo_usuario';
IF @df IS NOT NULL EXEC(N'ALTER TABLE dbo.usuario DROP CONSTRAINT [' + @df + N']');
GO

ALTER TABLE dbo.usuario ADD DEFAULT N'Encargado' FOR tipo_usuario;
GO
