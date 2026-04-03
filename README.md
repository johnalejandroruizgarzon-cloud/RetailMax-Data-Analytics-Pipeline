# RetailMax-Data-Analytics-Pipeline
End-to-end Data Engineering &amp; BI project. Includes synthetic data generation, Azure SQL pipeline (Bronze/Silver/Gold), and Power BI Executive Dashboard.
# RetailMax: Data Pipeline & Business Intelligence 🚀

Este proyecto presenta una solución integral de análisis de datos para el sector Retail, abarcando desde la generación de datos sintéticos hasta la visualización ejecutiva.

## Arquitectura del Proyecto
- **Generación:** Python (Faker, Pandas, Numpy) con semilla aleatoria fija (Seed: 42).
- **Almacenamiento:** Azure SQL Database estructurado en capas Medallion (Bronze, Silver, Gold).
- **BI:** Power BI Desktop con modelo estrella y métricas DAX avanzadas.

## Entregables Destacados
1. **Pipeline SQL:** Limpieza de anomalías (fechas futuras, negativos y nulos).
2. **Modelo Estrella:** Relaciones 1:* optimizadas para inteligencia de tiempo.
3. **Dashboard Ejecutivo:** KPIs de Ventas, Tasa de Devolución y Alertas de Stock.

## Cómo Replicar
1. Ejecutar los scripts de python "generate" para generar los archivos de origen .csv como datos crudos. Ejecutar en este orden debido a que existen dependencias de unas tablas con otras. (clientes, tiendas, proveedores, articulos, ventas, devoluciones, stock diario)
2. Ejecutar en la consola "load_to_sql.py" para cargar las tablas origen (Bronze) a SQL Database.
3. Cargar las tablas (Silver) en SQL Server usando los scripts de "Scripts_Tablas_Silver.sql".
4. Cargar las tablas (Gold) en SQL Server usando los scripts de "Scripts_Tablas_Gold.sql".
5. Abrir Power BI y conectarse a la base de datos. Server: sql-rtlmxjr26-dev.database.windows.net ; Database: RetailMaxDB ; username: Adminretail ; Pass: SuperPassword2026!
6. Actualizar e interactuar con el Dashboard

