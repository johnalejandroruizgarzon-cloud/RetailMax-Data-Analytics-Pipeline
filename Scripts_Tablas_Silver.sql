-- RECREACIÓN DE TABLA SILVER_CRM_MIEMBROS 

IF OBJECT_ID('SILVER_CRM_MIEMBROS', 'U') IS NOT NULL DROP TABLE SILVER_CRM_MIEMBROS; 

SELECT  

    -- 1. Identificadores y Enmascaramiento 

    id_miembro, 

    LEFT(CAST(id_miembro AS VARCHAR(50)), 2) +  

    REPLICATE('X', LEN(CAST(id_miembro AS VARCHAR(50))) - 4) +  

    RIGHT(CAST(id_miembro AS VARCHAR(50)), 2) AS id_miembro_mask, 

    
    -- 2. Fechas (Asegurando formato DATE) 

    CAST(fec_registro AS DATE) AS fec_registro, 

    CAST(fec_ultima_compra AS DATE) AS fec_ultima_compra, 

     
    -- 3. Ubicación y Atributos 

    id_ciudad, 


    -- 4. Estandarización de Género 

    CASE  

        WHEN genero IN ('M', 'Masculino', 'Hombre') THEN 'M' 

        WHEN genero IN ('F', 'Femenino', 'Mujer') THEN 'F' 

        ELSE 'No informado' 

    END AS genero_std, 

     

    -- 5. Rango de Edad Original 

    rango_edad, 

     

    -- 6. ASIGNACIÓN DE VALOR NUMÉRICO A RANGOS (Punto medio para cálculos) 

    CASE  

        WHEN rango_edad = '18-25' THEN 21.5 

        WHEN rango_edad = '26-35' THEN 30.5 

        WHEN rango_edad = '36-45' THEN 40.5 

        WHEN rango_edad = '46-60' THEN 53.0 

        WHEN rango_edad = '60+'   THEN 65.0 

        ELSE NULL  

    END AS edad_numerica_std, 

     

    -- 7. Otros campos 

    canal_pref, 

    activo 

 

INTO SILVER_CRM_MIEMBROS 

FROM CRM_MIEMBROS; 

 

-- Verificación de la carga 

SELECT TOP 10 * FROM SILVER_CRM_MIEMBROS; 




-- ========================================== 

-- 1. SILVER_ARTICULOS 

-- ========================================== 

IF OBJECT_ID('SILVER_ARTICULOS', 'U') IS NOT NULL DROP TABLE SILVER_ARTICULOS; 

 
 

SELECT  

    art_id, 

    cod_barra, 

    UPPER(TRIM(desc_art)) AS desc_art_std, -- Limpiamos espacios y pasamos a mayúsculas 

    id_categ_n1, 

    id_categ_n2, 

    id_categ_n3, 

     

    -- ID Proveedor Original (para el JOIN interno) 

    id_proveedor,  

     

    CAST(precio_lista AS DECIMAL(18,2)) AS precio_lista_std, 

    CAST(peso_kg AS DECIMAL(18,4)) AS peso_kg_std, 

    UPPER(unid_medida) AS unid_medida_std, 

    activo, 

    CAST(fec_alta AS DATE) AS fec_alta_std 

INTO SILVER_ARTICULOS 

FROM MSTR_ARTICULOS; 

 
 

-- ========================================== 

-- 2. SILVER_PROVEEDORES 

-- ========================================== 

IF OBJECT_ID('SILVER_PROVEEDORES', 'U') IS NOT NULL DROP TABLE SILVER_PROVEEDORES; 

 
 

SELECT  

    -- Como ya es BIGINT, no necesita TRIM. Solo aseguramos que sea un número limpio. 

    CAST(id_proveedor AS BIGINT) AS id_proveedor,  

     

    UPPER(TRIM(razon_social)) AS razon_social_std, 

    UPPER(TRIM(pais_origen)) AS pais_origen_std, 

    CAST(ISNULL(tiempo_repo_dias, 0) AS INT) AS tiempo_repo_dias, 

    calificacion_calidad, 

    activo 

INTO SILVER_PROVEEDORES 

FROM MSTR_PROVEEDORES; 

 
 

-- Verificación rápida 

SELECT TOP 5 * FROM SILVER_ARTICULOS; 

SELECT TOP 5 * FROM SILVER_PROVEEDORES; 


- 1. SILVER_VENTAS: Limpieza Profesional y Filtro de Anomalías Temporales 

-- ==========================================  

IF OBJECT_ID('SILVER_VENTAS', 'U') IS NOT NULL DROP TABLE SILVER_VENTAS;  

 
 

SELECT   

    id_trans,  

    ISNULL(id_miembro, 0) AS id_miembro,   

    id_tienda,  

    art_id,  

    CAST(fec_trans AS DATE) AS fec_trans_std,  

    hra_trans,  

      

    -- CORRECCIÓN DE NEGATIVOS 

    CAST(ABS(qty_vendida) AS INT) AS qty_vendida_std,  

      

    -- PROTECCIÓN CONTRA PRECIOS NEGATIVOS 

    CAST(ABS(precio_unitario_venta) AS DECIMAL(18,2)) AS precio_unitario_std,  

      

    -- PROTECCIÓN CONTRA NULOS EN DESCUENTO: Si es NULL, ponemos 0 para no romper la resta 

    CAST(ABS(ISNULL(descuento_aplicado, 0)) AS DECIMAL(18,2)) AS descuento_std,  

      

    UPPER(TRIM(tipo_pago)) AS tipo_pago_std,  

    UPPER(TRIM(canal_venta)) AS canal_venta_std  

INTO SILVER_VENTAS  

FROM TRANS_VENTAS 

-- FILTRO CRÍTICO: Eliminamos las fechas del futuro (Anomalía B) 

-- Solo permitimos ventas menores o iguales a la fecha de hoy 

WHERE CAST(fec_trans AS DATE) <= CAST(GETDATE() AS DATE); 


-- ========================================== 

-- 1. SILVER_STOCK_DIARIO: Limpieza y Tipado 

-- ========================================== 

IF OBJECT_ID('SILVER_STOCK_DIARIO', 'U') IS NOT NULL DROP TABLE SILVER_STOCK_DIARIO; 

 
 

SELECT  

    id_snapshot, 

    art_id, 

    id_tienda, 

    CAST(fec_snapshot AS DATE) AS fec_snapshot_std, 

     

    -- Manejo de negativos y nulos en stock (no puede haber stock negativo) 

    CAST(ABS(ISNULL(stock_fisico, 0)) AS INT) AS stock_fisico_std, 

    CAST(ABS(ISNULL(stock_transito, 0)) AS INT) AS stock_transito_std, 

    CAST(ABS(ISNULL(stock_reservado, 0)) AS INT) AS stock_reservado_std, 

     

    CAST(stock_minimo_config AS INT) AS stock_minimo, 

    CAST(stock_maximo_config AS INT) AS stock_maximo 

INTO SILVER_STOCK_DIARIO 

FROM INV_STOCK_DIARIO; 

 
 

-- Verificación rápida 

SELECT TOP 100 * FROM SILVER_STOCK_DIARIO; 



-- ========================================== 

-- 1. SILVER_DEVOLUCIONES: Limpieza y Tipado 

-- ========================================== 

IF OBJECT_ID('SILVER_DEVOLUCIONES', 'U') IS NOT NULL DROP TABLE SILVER_DEVOLUCIONES; 

 
 

SELECT  

    id_devolucion, 

    id_trans_origen, -- Llave para unir con fact_ventas 

    art_id, 

    id_tienda, 

    CAST(fec_devolucion AS DATE) AS fec_devolucion_std, 

     

    -- Cantidad devuelta (siempre positiva para el cálculo) 

    CAST(ABS(qty_devuelta) AS INT) AS qty_devuelta_std, 

     

    UPPER(TRIM(motivo_cod)) AS motivo_cod_raw, 

    UPPER(TRIM(canal_devolucion)) AS canal_devolucion_std, 

    UPPER(TRIM(estado_devolucion)) AS estado_std, 

     

    CAST(ABS(vr_reembolso) AS DECIMAL(18,2)) AS vr_reembolso_std 

INTO SILVER_DEVOLUCIONES 

FROM POST_DEVOLUCIONES; 

 
 

-- Verificación rápida 

SELECT TOP 100 * FROM SILVER_DEVOLUCIONES; 

