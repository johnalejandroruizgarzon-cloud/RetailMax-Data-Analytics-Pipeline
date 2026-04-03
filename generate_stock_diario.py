import pandas as pd
import numpy as np
import os

# 1. Configuración Inicial
np.random.seed(42)
N_RECORDS = 15000 #Muestra de los 750.000

print(f"Generando {N_RECORDS} registros de inventario diario...")

# 2. Generación Vectorizada de IDs
id_snapshot = np.arange(1, N_RECORDS + 1)
art_id = np.random.randint(1, 101, N_RECORDS)   # Conecta con MSTR_ARTICULOS
id_tienda = np.random.randint(1, 26, N_RECORDS) # Conecta con MSTR_TIENDAS (160 tiendas en total)

# 3. Generación de Fechas (Últimos 30 días para análisis de tendencias recientes)
# Fijamos una fecha de inicio reciente para simular el snapshot operativo actual
start_date = pd.to_datetime('2026-03-01')
random_days = np.random.randint(0, 31, N_RECORDS)
fec_snapshot = start_date + pd.to_timedelta(random_days, unit='D')

# 4. Lógica de Configuración de Stock (Mínimos y Máximos)
# El mínimo de seguridad suele estar entre 10 y 50 unidades, el máximo entre 80 y 300
stock_minimo_config = np.random.randint(10, 51, N_RECORDS)
stock_maximo_config = stock_minimo_config + np.random.randint(70, 250, N_RECORDS)

# 5. Lógica de Negocio: Simulando la Realidad del Inventario
# Vamos a crear una distribución realista para desafiar tu modelo en Power BI:
# - 15% de los registros tendrán stock crítico o quiebre (Riesgo de pérdida del 3-8%)
# - 75% estarán en niveles normales (entre el mínimo y el máximo)
# - 10% tendrán sobrestock (por encima del máximo)

condicion_prob = np.random.rand(N_RECORDS)
cond_critico = condicion_prob < 0.15
cond_normal = (condicion_prob >= 0.15) & (condicion_prob < 0.90)
cond_sobrestock = condicion_prob >= 0.90

# Inicializamos el arreglo de stock físico
stock_fisico = np.zeros(N_RECORDS, dtype=int)

# Asignamos valores según la condición usando np.where para operaciones vectorizadas
# Crítico: entre 0 y el límite mínimo
stock_fisico = np.where(cond_critico, 
                        np.random.randint(0, stock_minimo_config + 1), 
                        stock_fisico)

# Normal: entre el mínimo y el máximo
stock_fisico = np.where(cond_normal, 
                        np.random.randint(stock_minimo_config, stock_maximo_config + 1), 
                        stock_fisico)

# Sobrestock: por encima del máximo
stock_fisico = np.where(cond_sobrestock, 
                        stock_maximo_config + np.random.randint(1, 50, N_RECORDS), 
                        stock_fisico)

# 6. Stock en Tránsito y Reservado
# El tránsito suele ocurrir cuando se reabastece desde Bogotá, CDMX o Santiago (1 a 3 días)
# Solo un 20% de las veces hay mercancía en camino
stock_transito = np.where(np.random.rand(N_RECORDS) < 0.20, 
                          np.random.randint(20, 150, N_RECORDS), 
                          0)

# El stock reservado (compras online pendientes de despacho) aplica en un 10% de los casos
stock_reservado = np.where(np.random.rand(N_RECORDS) < 0.10, 
                           np.random.randint(1, 15, N_RECORDS), 
                           0)

# 7. Ensamblaje del DataFrame
df_inventario = pd.DataFrame({
    'id_snapshot': id_snapshot,
    'art_id': art_id,
    'id_tienda': id_tienda,
    # fec_snapshot es un DatetimeIndex, usamos .date para extraer solo la fecha limpia
    'fec_snapshot': fec_snapshot.date, 
    'stock_fisico': stock_fisico,
    'stock_transito': stock_transito,
    'stock_reservado': stock_reservado,
    'stock_minimo_config': stock_minimo_config,
    'stock_maximo_config': stock_maximo_config
})

# 8. Exportación a CSV
base_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(base_dir)
data_path = os.path.join(project_root, "data", "raw")
os.makedirs(data_path, exist_ok=True)

file_path = os.path.join(data_path, "INV_STOCK_DIARIO.csv")
df_inventario.to_csv(file_path, index=False)

# Validación Técnica
print("\n--- Muestra de los datos ---")
print(df_inventario.head())
print("\n--- Análisis Rápido de Quiebres (Stock Físico = 0) ---")
quiebres = len(df_inventario[df_inventario['stock_fisico'] == 0])
porcentaje_quiebres = (quiebres / N_RECORDS) * 100
print(f"Total de registros con quiebre total: {quiebres:,} ({porcentaje_quiebres:.2f}%)")
print("-" * 50)
print(f"Éxito: Se generaron {len(df_inventario):,} registros en {file_path}")