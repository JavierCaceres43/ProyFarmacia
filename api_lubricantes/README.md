# API Inventario de Lubricantes

API Node.js + Express + TypeScript + SQL Server para la interfaz de InventarioLubricantesDB.

## 1. Instalar

```bash
npm install
```

## 2. Configurar

Copiar `.env.example` como `.env` y completar la conexión a SQL Server.

Ejemplo:

```env
PORT=3000
DB_HOST=localhost
DB_PORT=1433
DB_NAME=InventarioLubricantesDB
DB_USER=sa
DB_PASSWORD=TU_PASSWORD
DB_TRUSTED_CONNECTION=false
DB_TRUST_SERVER_CERTIFICATE=true
```

## 3. Ejecutar

```bash
npm run dev
```

## 4. Abrir la interfaz

Con el servidor en marcha, abre http://localhost:3000 . La interfaz está en `public/index.html` y la sirve el mismo Express, así que no hay problemas de CORS ni hace falta otro servidor.

Conectado al API: **Inicio** (estadísticas y productos recientes) y **Productos** (buscar, crear, editar, desactivar). Ventas, Clientes, Usuarios, Lotes y Reportes muestran datos de ejemplo hasta que existan sus endpoints.

## Endpoints actuales

- GET `/api/health`
- GET `/api/dashboard`
- GET `/api/productos`
- GET `/api/productos?q=castrol`
- GET `/api/productos/:id`
- POST `/api/productos`
- PUT `/api/productos/:id`
- DELETE `/api/productos/:id`  -> borrado lógico (`activo=0`)

## Ejemplo POST/PUT producto

```json
{
  "nombre_producto": "CASTROL GTX 20W-50",
  "descripcion_producto": "Aceite multigrado para motor",
  "id_categoria": 1,
  "precio_compra": 35.00,
  "precio_venta": 45.00,
  "stock_minimo": 5
}
```

## Arquitectura

Frontend React/TypeScript -> API Express -> SQL Server (`InventarioLubricantesDB`).

Las operaciones de venta/compra y stock deben conectarse a los procedimientos almacenados del proyecto (`sp_Venta_Registrar`, `sp_Venta_Anular`, `sp_Compra_Registrar`, `sp_Compra_Anular`, `sp_Producto_ActualizarStock`, `sp_Lote_ActualizarEstado`, etc.) antes de habilitar esas operaciones desde la interfaz.

> Nota: `Producto` debe conservar los nombres de columnas usados por el script actual. Si tu versión final del script tiene una firma distinta, solo se ajusta el service correspondiente; no hace falta cambiar la interfaz.
