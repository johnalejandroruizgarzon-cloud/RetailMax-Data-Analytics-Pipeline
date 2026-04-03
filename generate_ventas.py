import pandas as pd
import numpy as np
import os
from datetime import datetime

# 1. Configuración Inicial
np.random.seed(42)
N_RECORDS = 100000 

# --- CARGA DE MIEMBROS REALES PARA MANTENER COHERENCIA ---
base_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(base_dir)
miembros_path = os.path.join(project_root, "data", "raw", "CRM_MIEMBROS.csv")

if not os.path.exists(miembros_path):
    print("Error: No se encuentra CRM_MIEMBROS.csv. Genéralo primero con los IDs largos.")
else:
    df_miembros_base = pd.read_csv(miembros_path)
    # Extraemos la lista de IDs reales que generamos de 6 a 9 dígitos
    ids_reales_clientes = df_miembros_base['id_miembro'].unique()
    
    print(f"Generando {N_RECORDS} ventas vinculadas a {len(ids_reales_clientes)} clientes reales...")

    # 2. Generación Vectorizada de IDs
    id_trans = np.arange(1, N_RECORDS + 1)
    
    # ASIGNACIÓN COHERENTE: Seleccionamos solo de los IDs que existen en el CRM
    id_miembro = np.random.choice(ids_reales_clientes, size=N_RECORDS)
    
    # Ajustamos el rango de artículos a lo que definimos previamente (1 a 100)
    art_id = np.random.randint(1, 101, N_RECORDS) #Muestra de 5.000

    # 3. Lógica de Tiendas y Canal de Venta
    es_digital = np.random.choice([True, False], size=N_RECORDS, p=[0.25, 0.75])
    id_tienda = np.where(
        es_digital, 
        np.random.choice([23, 25], size=N_RECORDS), 
        np.random.randint(1, 22, size=N_RECORDS)
    )
    canal_venta = np.where(es_digital, 'Digital', 'Físico')

    # 4. Fechas y Horas (Últimos 3 años)
    start_date = pd.to_datetime('2023-01-01')
    end_date = pd.to_datetime('today')
    days_diff = (end_date - start_date).days
    random_days = np.random.randint(0, days_diff, N_RECORDS)
    fec_trans = start_date + pd.to_timedelta(random_days, unit='D')
    random_seconds = np.random.randint(8 * 3600, 22 * 3600, N_RECORDS)
    hra_trans = (pd.to_datetime('2023-01-01') + pd.to_timedelta(random_seconds, unit='s')).strftime('%H:%M:%S')

    # 5. Cantidades, Precios y Descuentos
    qty_vendida = np.random.choice([1, 2, 3, 4, 5, 10], p=[0.50, 0.25, 0.15, 0.05, 0.03, 0.02], size=N_RECORDS)
    precio_unitario_venta = np.round(np.random.uniform(1500, 250000, N_RECORDS), 2)
    descuento_aplicado = np.random.choice([0.0, 0.05, 0.10, 0.20], p=[0.70, 0.15, 0.10, 0.05], size=N_RECORDS)

    # 6. Métodos de Pago
    pagos_fisicos = np.random.choice(['Efectivo', 'Tarjeta de Crédito', 'Tarjeta de Débito'], size=N_RECORDS, p=[0.4, 0.4, 0.2])
    pagos_digitales = np.random.choice(['Tarjeta de Crédito', 'Tarjeta de Débito', 'Billetera Digital'], size=N_RECORDS, p=[0.6, 0.2, 0.2])
    tipo_pago = np.where(es_digital, pagos_digitales, pagos_fisicos)

    # 7. Ensamblaje del DataFrame
    df_ventas = pd.DataFrame({
        'id_trans': id_trans,
        'id_miembro': id_miembro,
        'id_tienda': id_tienda,
        'art_id': art_id,
        'fec_trans': fec_trans.date,
        'hra_trans': hra_trans,
        'qty_vendida': qty_vendida,
        'precio_unitario_venta': precio_unitario_venta,
        'descuento_aplicado': descuento_aplicado,
        'tipo_pago': tipo_pago,
        'canal_venta': canal_venta
    })

# 8. Inyección de Anomalías (Para tu limpieza en Silver)
#Nulos controlados (5% en descuento_aplicado) usando tu lógica de random.choice 

mask_nulos = np.random.choice([True, False], size=N_RECORDS, p=[0.05, 0.95]) 
df_ventas.loc[mask_nulos, 'descuento_aplicado'] = np.nan

indices_anomalias = np.random.choice(df_ventas.index, size=3000, replace=False)
    
# Anomalía A: Cantidades negativas
df_ventas.loc[indices_anomalias[0:1000], 'qty_vendida'] = -1
    
# Anomalía B: Fechas del futuro
df_ventas.loc[indices_anomalias[1000:2000], 'fec_trans'] = pd.to_datetime('2030-01-01').date()
    
# Anomalía C: IDs Huérfanos (Solo 1000 para no dañar todo el reporte)
df_ventas.loc[indices_anomalias[2000:3000], 'id_miembro'] = 999 

# 9. Exportación
data_path = os.path.join(project_root, "data", "raw")
os.makedirs(data_path, exist_ok=True)
file_path = os.path.join(data_path, "TRANS_VENTAS.csv")
    
# Aseguramos que los IDs sean enteros limpios
df_ventas['id_miembro'] = df_ventas['id_miembro'].astype(int)
df_ventas.to_csv(file_path, index=False)

print("\n--- Muestra de los datos ---") 
print(df_ventas.head()) 
print("\n--- Distribución por Canal ---") 
print(df_ventas['canal_venta'].value_counts(normalize=True).mul(100).round(2).astype(str) + '%') 
print("-" * 50) 
print(f"Éxito: Se generaron {len(df_ventas):,} registros en {file_path}") 