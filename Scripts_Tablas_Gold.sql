-- 1. CREACIÓN DE LA TABLA GOLD: dim_clientes 

IF OBJECT_ID('dim_clientes', 'U') IS NOT NULL DROP TABLE dim_clientes; 

 
 

WITH MedianaCalculada AS ( 

    -- Calculamos la mediana numérica por cada canal de preferencia 

    SELECT DISTINCT 

        canal_pref, 

        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY edad_numerica_std)  

            OVER (PARTITION BY canal_pref) AS mediana_numerica_canal 

    FROM SILVER_CRM_MIEMBROS 

    WHERE edad_numerica_std IS NOT NULL 

), 

MedianaAMapeo AS ( 

    -- Convertimos esa mediana numérica de vuelta al rango de texto correspondiente 

    SELECT  

        canal_pref, 

        CASE  

            WHEN mediana_numerica_canal <= 25 THEN '18-25' 

            WHEN mediana_numerica_canal <= 35 THEN '26-35' 

            WHEN mediana_numerica_canal <= 45 THEN '36-45' 

            WHEN mediana_numerica_canal <= 60 THEN '46-60' 

            ELSE '60+'  

        END AS rango_edad_imputado 

    FROM MedianaCalculada 

) 

SELECT  

    -- EXCLUIMOS id_miembro por seguridad, solo dejamos la versión enmascarada 

    S.id_miembro, 

S.id_miembro_mask, 

     

    -- Atributos demográficos estandarizados 

    S.genero_std AS genero, 

     

    -- Imputación lógica: Si el rango es nulo, usamos el rango de la mediana de su canal 

    ISNULL(S.rango_edad, M.rango_edad_imputado) AS rango_edad, 

     

    -- Cálculos de negocio requeridos en la prueba 

    S.fec_registro, 

    DATEDIFF(DAY, S.fec_registro, GETDATE()) AS antiguedad_dias, 

    S.fec_ultima_compra, 

     

    -- Atributos de segmentación y localización 

    S.id_ciudad, 

    S.canal_pref, 

    S.activo 

 
 

INTO dim_clientes 

FROM SILVER_CRM_MIEMBROS S 

LEFT JOIN MedianaAMapeo M ON S.canal_pref = M.canal_pref; 

 
 

-- 2. VERIFICACIÓN DE LA TABLA GOLD 

SELECT TOP 50 * FROM dim_clientes; 




-- ========================================== 

-- CREACIÓN DE LA TABLA GOLD: dim_productos 

-- ========================================== 

IF OBJECT_ID('dim_productos', 'U') IS NOT NULL DROP TABLE dim_productos; 

 
 

SELECT  

    -- 1. Información Básica del Producto 

    A.art_id, 

    A.cod_barra, 

    A.desc_art_std AS nombre_producto, 

     

    -- 2. Jerarquía de Categorías (Campos Planos) 

    -- Aquí podrías unir con una tabla maestra de categorías si existiera,  

    -- por ahora mantenemos los IDs como pide la estructura de la prueba. 

    A.id_categ_n1 AS categoria_nivel_1, 

    A.id_categ_n2 AS categoria_nivel_2, 

    A.id_categ_n3 AS categoria_nivel_3, 

     

    -- 3. Información del Proveedor (Join) 

    A.id_proveedor, 

    P.razon_social_std AS nombre_proveedor, 

    P.pais_origen_std AS pais_proveedor, 

     

    -- 4. Atributos Físicos y de Costo 

    A.precio_lista_std AS precio_lista, 

    A.peso_kg_std AS peso_kg, 

    A.unid_medida_std AS unidad_medida, 

     

    -- 5. Lógica de Negocio: Margen Estimado por Categoría 

    -- Ejemplo: Nivel 1 es Gran Categoría (Tecnología 10%, Ropa 40%, Alimentos 15%) 

    CASE  

        WHEN A.id_categ_n1 = 1 THEN CAST(A.precio_lista_std * 0.10 AS DECIMAL(18,2)) -- Tecnología 

        WHEN A.id_categ_n1 = 2 THEN CAST(A.precio_lista_std * 0.15 AS DECIMAL(18,2)) -- Alimentos 

        WHEN A.id_categ_n1 = 3 THEN CAST(A.precio_lista_std * 0.40 AS DECIMAL(18,2)) -- Textil/Ropa 

        ELSE CAST(A.precio_lista_std * 0.20 AS DECIMAL(18,2)) -- Margen genérico del 20% 

    END AS margen_estimado_valor, 

     

    -- 6. Auditoría y Estado 

    A.activo AS producto_activo, 

    A.fec_alta_std AS fecha_alta_sistema 

 
 

INTO dim_productos 

FROM SILVER_ARTICULOS A 

LEFT JOIN SILVER_PROVEEDORES P ON A.id_proveedor = P.id_proveedor; 

 
 

-- Verificación de la tabla Gold 

SELECT TOP 100 * FROM dim_productos; 



-- ========================================== 

-- CREACIÓN DE LA TABLA GOLD: dim_tiendas

-- ========================================== 



IF OBJECT_ID('dim_tiendas', 'U') IS NOT NULL DROP TABLE dim_tiendas; 

 

SELECT  

    id_tienda, 

    nom_tienda_std AS nombre_tienda, 

     

    -- A. Catálogo Controlado de Tipos de Tienda 

    CASE  

        WHEN tipo_tienda_raw LIKE '%hiper%' THEN 'Hipermercado' 

        WHEN tipo_tienda_raw LIKE '%super%' THEN 'Supermercado' 

        WHEN tipo_tienda_raw LIKE '%conveniencia%' OR tipo_tienda_raw = 'conv' THEN 'Conveniencia' 

        ELSE 'Otro / No Definido' 

    END AS tipo_tienda_controlado, 

     

    -- B. Enriquecimiento de País (Basado en tu diccionario) 

    CASE  

        WHEN id_pais = 1 THEN 'Colombia' 

        WHEN id_pais = 2 THEN 'México' 

        WHEN id_pais = 3 THEN 'Chile' 

        WHEN id_pais = 4 THEN 'Perú' 

        WHEN id_pais = 5 THEN 'Ecuador' 

        ELSE 'Otro País' 

    END AS pais_nombre, 

     

    -- C. Enriquecimiento de Ciudad (Basado en tu diccionario) 

    CASE  

        WHEN id_ciudad = 1 THEN 'Bogotá' 

        WHEN id_ciudad = 2 THEN 'Medellín' 

        WHEN id_ciudad = 3 THEN 'Cali' 

        WHEN id_ciudad = 4 THEN 'CDMX' 

        WHEN id_ciudad = 5 THEN 'Monterrey' 

        WHEN id_ciudad = 6 THEN 'Guadalajara' 

        WHEN id_ciudad = 7 THEN 'Santiago' 

        WHEN id_ciudad = 8 THEN 'Lima' 

        WHEN id_ciudad = 9 THEN 'Quito' 

        WHEN id_ciudad = 10 THEN 'Guayaquil' 

        WHEN id_ciudad = 11 THEN 'Cuenca' 

        ELSE 'Ciudad No Registrada' 

    END AS ciudad_nombre, 

     

    -- D. Cálculo de Zona de Distribución (Lógica por Bloque Regional) 

    CASE  

        WHEN id_pais IN (1, 4, 5) THEN 'Zona Andina' 

        WHEN id_pais = 2 THEN 'Zona Norte (México)' 

        WHEN id_pais = 3 THEN 'Zona Sur (Chile)' 

        ELSE 'Zona Internacional' 

    END AS zona_distribucion, 

     

    metros_cuadrados_std AS metros_cuadrados, 

    fec_apertura_std AS fecha_apertura, 

    activo 

INTO dim_tiendas 

FROM SILVER_TIENDAS; 

 
 

-- Verificación final 

SELECT TOP 20 * FROM dim_tiendas; 



-- ========================================== 

-- 2. fact_ventas: Métricas y Validación 

-- ========================================== 

IF OBJECT_ID('fact_ventas', 'U') IS NOT NULL DROP TABLE fact_ventas; 

 
 

SELECT  

    V.id_trans, 

    V.fec_trans_std AS fecha_id, -- Llave para la tabla de tiempo 

    V.id_tienda, 

    V.art_id, 

    V.id_miembro, 
 

    -- A. Validación contra dim_clientes (Seguridad y Consistencia) 

    -- Si el ID no existe en dim_clientes (porque usamos la máscara allá),  

    -- aquí usaremos el id_miembro_mask de la dimensión. 

    ISNULL(C.id_miembro_mask, 'ANONIMO_0000') AS id_miembro_mask, 

     

    V.qty_vendida_std AS cantidad, 

    V.precio_unitario_std AS precio_unitario, 

    V.descuento_std AS descuento, 

     

    -- B. Cálculo vr_venta_neto = qty_vendida x precio_unitario - descuento 

    CAST((V.qty_vendida_std * V.precio_unitario_std) - V.descuento_std AS DECIMAL(18,2)) AS vr_venta_neto, 

     

    -- C. Agregar indicador de venta con descuento (Flag) 

    CASE  

        WHEN V.descuento_std > 0 THEN 1  

        ELSE 0  

    END AS ind_con_descuento, 

     

    V.tipo_pago_std AS metodo_pago, 

    V.canal_venta_std AS canal 

INTO fact_ventas 

FROM SILVER_VENTAS V 

-- Nota: Aquí unimos con dim_clientes para validar existencia (basado en el ID original que guardamos en Silver) 

LEFT JOIN SILVER_CRM_MIEMBROS C ON V.id_miembro = C.id_miembro; 

 
 

-- Verificación final Gold 

SELECT TOP 100 * FROM fact_ventas; 


-- ========================================== 

-- 2. fact_inventario: Lógica de Abastecimiento 

-- ========================================== 

IF OBJECT_ID('fact_inventario', 'U') IS NOT NULL DROP TABLE fact_inventario; 

 
 

WITH VentasDiarias AS ( 

    -- Paso A: Total de ventas por día/artículo/tienda 

    SELECT  

        fec_trans_std,  

        art_id,  

        id_tienda,  

        SUM(qty_vendida_std) AS total_dia 

    FROM SILVER_VENTAS 

    GROUP BY fec_trans_std, art_id, id_tienda 

), 

PromedioConsumo AS ( 

    -- Paso B: Calculamos el promedio móvil de los últimos 14 días 

    -- Usamos ROWS BETWEEN 13 PRECEDING AND CURRENT ROW 

    SELECT  

        fec_trans_std, art_id, id_tienda, 

        AVG(CAST(total_dia AS FLOAT)) OVER ( 

            PARTITION BY art_id, id_tienda  

            ORDER BY fec_trans_std  

            ROWS BETWEEN 13 PRECEDING AND CURRENT ROW 

        ) AS avg_consumo_14d 

    FROM VentasDiarias 

) 

SELECT  

    S.id_snapshot, 

    S.fec_snapshot_std AS fecha_id, 

    S.art_id, 

    S.id_tienda, 

    S.stock_fisico_std AS stock_actual, 

     

    -- 1. Traer el promedio de consumo calculado 

    CAST(ISNULL(P.avg_consumo_14d, 0) AS DECIMAL(18,2)) AS promedio_consumo_14dias, 

     

    -- 2. Calcular cobertura_dias = stock_fisico / promedio_consumo (evitando división por cero) 

    CAST( 

        CASE  

            WHEN ISNULL(P.avg_consumo_14d, 0) = 0 THEN 999 -- Si no se vende, la cobertura es "infinita" 

            ELSE S.stock_fisico_std / P.avg_consumo_14d  

        END AS DECIMAL(18,2) 

    ) AS cobertura_dias, 

     

    -- 3. Flag alerta_quiebre (1 si cobertura < 7 días) 

    CASE  

        WHEN (S.stock_fisico_std / NULLIF(P.avg_consumo_14d, 0)) < 7 THEN 1  

        ELSE 0  

    END AS alerta_quiebre, 

     

    -- 4. Diferencia frente a stock_minimo_config 

    (S.stock_fisico_std - S.stock_minimo) AS diferencia_vs_minimo 

 
 

INTO fact_inventario 

FROM SILVER_STOCK_DIARIO S 

LEFT JOIN PromedioConsumo P ON S.art_id = P.art_id  

                            AND S.id_tienda = P.id_tienda  

                            AND S.fec_snapshot_std = P.fec_trans_std; 

 
 

-- Verificación final 

SELECT TOP 500 * FROM fact_inventario; 



-- ========================================== 

-- 2. fact_devoluciones: Análisis de Calidad con Categorías Específicas 

-- ========================================== 

IF OBJECT_ID('fact_devoluciones', 'U') IS NOT NULL DROP TABLE fact_devoluciones; 

 
 

-- Calculamos totales de venta por artículo para la tasa de devolución 

WITH TotalesVenta AS ( 

    SELECT art_id, SUM(qty_vendida_std) AS total_vendido 

    FROM SILVER_VENTAS 

    GROUP BY art_id 

) 

SELECT  

    D.id_devolucion, 

    D.id_trans_origen, 

    D.art_id, 

    D.id_tienda, 

    D.fec_devolucion_std AS fecha_id, 

     

    -- 1. Join con Venta Origen para obtener precio original 

    V.precio_unitario_venta AS precio_original_venta, 

    D.qty_devuelta_std AS cantidad_devuelta, 

    D.vr_reembolso_std AS valor_reembolsado, 

 
 

    -- 2. Estandarizar motivo_cod a tus categorías exactas 

    CASE  

        WHEN D.motivo_cod_raw LIKE '%DEF%' OR D.motivo_cod_raw = 'FABRICA' THEN 'Defecto de fábrica' 

        WHEN D.motivo_cod_raw LIKE '%TALLA%' OR D.motivo_cod_raw = 'COLOR' THEN 'Talla/Color incorrecto' 

        WHEN D.motivo_cod_raw LIKE '%EXP%' OR D.motivo_cod_raw = 'EXPECTATIVA' THEN 'No cumple expectativas' 

        WHEN D.motivo_cod_raw LIKE '%DANO%' OR D.motivo_cod_raw = 'TRANSPORTE' THEN 'Llegó dañado por transporte' 

        WHEN D.motivo_cod_raw LIKE '%RETRASO%' OR D.motivo_cod_raw = 'ENTREGA' THEN 'Retraso en entrega' 

        WHEN D.motivo_cod_raw LIKE '%ERR%' OR D.motivo_cod_raw = 'EQUIVOCADO' THEN 'Producto erróneo' 

        ELSE 'Otro Motivo / No Especificado' 

    END AS motivo_desc, 

 
 

    -- 3. Calcular tasa_devolucion por artículo 

    CAST( 

        ISNULL(CAST(D.qty_devuelta_std AS FLOAT) / NULLIF(T.total_vendido, 0), 0)  

        AS DECIMAL(18,4) 

    ) AS tasa_devolucion_art, 

 
 

    D.canal_devolucion_std AS canal, 

    D.estado_std AS estado_proceso 

 
 

INTO fact_devoluciones 

FROM SILVER_DEVOLUCIONES D 

LEFT JOIN TRANS_VENTAS V ON D.id_trans_origen = V.id_trans AND D.art_id = V.art_id 

LEFT JOIN TotalesVenta T ON D.art_id = T.art_id; 

 
 

SELECT TOP 100 * FROM fact_devoluciones; 



-- ========================================== 

-- ACTUALIZACIÓN FINAL: fact_rfm_clientes 

-- ========================================== 

IF OBJECT_ID('fact_rfm_clientes', 'U') IS NOT NULL DROP TABLE fact_rfm_clientes; 

 
 

WITH ClientesActivos AS ( 

    -- Paso A: Identificar clientes con al menos una compra en los últimos 180 días 

    SELECT DISTINCT id_miembro AS id_miembro 

    FROM SILVER_VENTAS 

    WHERE fec_trans_std >= DATEADD(DAY, -180, GETDATE()) 

      AND id_miembro <> 0 

), 

MetricasRFM AS ( 

    -- Paso B: Calcular R, F, M solo sobre los últimos 90 días para los clientes activos 

    SELECT  

        V.id_miembro AS id_miembro, 

        DATEDIFF(DAY, MAX(V.fec_trans_std), GETDATE()) AS recencia, 

        -- Frecuencia y Monetario solo de los últimos 90 días 

        COUNT(DISTINCT CASE WHEN V.fec_trans_std >= DATEADD(DAY, -90, GETDATE()) THEN V.id_trans END) AS frecuencia_90d, 

        SUM(CASE WHEN V.fec_trans_std >= DATEADD(DAY, -90, GETDATE()) THEN (V.qty_vendida_std * V.precio_unitario_std - V.descuento_std) ELSE 0 END) AS monetario_90d 

    FROM SILVER_VENTAS V 

    INNER JOIN ClientesActivos A ON V.id_miembro = A.id_miembro 

    GROUP BY V.id_miembro 

), 

ScoresQuintiles AS ( 

    -- Paso C: Asignar scores 1-5 mediante quintiles sobre el universo de activos 

    SELECT  

        id_miembro, 

        recencia, frecuencia_90d, monetario_90d, 

        -- Recencia: Menos días es mejor (Score 5) 

        NTILE(5) OVER (ORDER BY recencia DESC) AS score_R, 

        -- Frecuencia: Más transacciones es mejor (Score 5) 

        NTILE(5) OVER (ORDER BY frecuencia_90d ASC) AS score_F, 

        -- Monetario: Más valor es mejor (Score 5) 

        NTILE(5) OVER (ORDER BY monetario_90d ASC) AS score_M 

    FROM MetricasRFM 

) 

SELECT  

    S.id_miembro, 

    C.id_miembro_mask, 

    S.recencia AS dias_desde_ultima_compra, 

    S.frecuencia_90d AS transacciones_90d, 

    S.monetario_90d AS valor_monetario_90d, 

     

    -- Formato exacto solicitado: R5-F4-M5 

    'R' + CAST(S.score_R AS VARCHAR) + '-F' + CAST(S.score_F AS VARCHAR) + '-M' + CAST(S.score_M AS VARCHAR) AS rfm_score_label, 

     

    -- Definición de Grupos de Valor (5 Grupos base + Especiales) 

    CASE  

        WHEN S.score_R = 5 AND S.score_F = 5 AND S.score_M = 5 THEN 'Champions' 

        WHEN S.score_R >= 4 AND S.score_F >= 4 THEN 'Leales Potenciales' 

        WHEN S.score_R <= 2 AND S.score_M >= 4 THEN 'Clientes en Riesgo' 

        WHEN S.score_R <= 1 THEN 'Hibernando / Perdidos' 

        ELSE 'Clientes Promedio' 

    END AS segmento_valor, 

     

    CAST(GETDATE() AS DATE) AS fecha_actualizacion_semanal 

INTO fact_rfm_clientes 

FROM ScoresQuintiles S 

JOIN SILVER_CRM_MIEMBROS C ON S.id_miembro = C.id_miembro; 

SELECT TOP 100 * FROM fact_rfm_clientes; 