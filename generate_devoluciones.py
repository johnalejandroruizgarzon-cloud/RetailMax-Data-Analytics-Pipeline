import pandas as pd
import numpy as np
import os

# 1. Configuración Inicial
np.random.seed(42)
N_RECORDS = 1000 

# CARGA DE DATOS DE ORIGEN PARA MANTENER RELACIÓN
# Necesitamos leer las ventas reales para saber qué podemos devolver
base_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(base_dir)
ventas_path = os.path.join(project_root, "data", "raw", "TRANS_VENTAS.csv")

if not os.path.exists(ventas_path):
    print("Error: No se encuentra TRANS_VENTAS.csv. Genéralo primero.")
else:
    df_ventas = pd.read_csv(ventas_path)
    
    print(f"Generando {N_RECORDS} registros de devoluciones basados en ventas reales...")

    # 2. Selección Aleatoria de Ventas Existentes
    # Seleccionamos N filas de las ventas para que la devolución sea de un producto que SI se vendió
    indices_ventas = np.random.choice(df_ventas.index, size=N_RECORDS, replace=True)
    ventas_muestreadas = df_ventas.loc[indices_ventas].copy()

    # 3. Generación de Datos de Devolución
    id_devolucion = np.arange(1, N_RECORDS + 1)
    
    # Heredamos los IDs directamente de la venta original para asegurar el JOIN
    id_trans_origen = ventas_muestreadas['id_trans'].values
    art_id = ventas_muestreadas['art_id'].values
    id_tienda = ventas_muestreadas['id_tienda'].values
    
    # 4. Lógica de Fechas (Debe ser posterior a la fecha de venta)
    # Tomamos la fecha de venta y le sumamos entre 1 y 15 días
    fec_venta = pd.to_datetime(ventas_muestreadas['fec_trans'])
    fec_devolucion = fec_venta + pd.to_timedelta(np.random.randint(1, 16, N_RECORDS), unit='D')

    # 5. Cantidades y Reembolsos (No puede devolver más de lo que compró)
    qty_comprada = ventas_muestreadas['qty_vendida'].values
    # Por simplicidad, devolvemos el total de la línea o una parte
    qty_devuelta = np.array([np.random.randint(1, q + 1) if q > 1 else 1 for q in qty_comprada])
    
    # El reembolso real: Precio original x cantidad devuelta (menos una parte del descuento proporcional)
    precio_unitario = ventas_muestreadas['precio_unitario_venta'].values
    vr_reembolso = np.round(qty_devuelta * precio_unitario, 2)

    # 6. Motivos y Canales (Tus categorías)
    motivos = ['Defecto de fábrica', 'Talla/Color incorrecto', 'No cumple expectativas', 
               'Llegó dañado por transporte', 'Retraso en entrega', 'Producto erróneo']
    motivo_cod = np.random.choice(motivos, p=[0.35, 0.25, 0.20, 0.15, 0.04, 0.01], size=N_RECORDS)

    canales = ['Tienda Física', 'Recolección Domicilio', 'Punto de Entrega/Correo']
    canal_devolucion = np.random.choice(canales, p=[0.60, 0.25, 0.15], size=N_RECORDS)

    estados = ['Aprobado', 'Rechazado', 'En Revisión']
    estado_devolucion = np.random.choice(estados, p=[0.85, 0.05, 0.10], size=N_RECORDS)

    # 7. Ensamblaje del DataFrame
    df_devoluciones = pd.DataFrame({
        'id_devolucion': id_devolucion,
        'id_trans_origen': id_trans_origen,
        'art_id': art_id,
        'id_tienda': id_tienda,
        'fec_devolucion': fec_devolucion.dt.date, 
        'qty_devuelta': qty_devuelta,
        'motivo_cod': motivo_cod,
        'canal_devolucion': canal_devolucion,
        'estado_devolucion': estado_devolucion,
        'vr_reembolso': vr_reembolso
    })

    # 8. Exportación
    data_path = os.path.join(project_root, "data", "raw")
    file_path = os.path.join(data_path, "POST_DEVOLUCIONES.csv")
    df_devoluciones.to_csv(file_path, index=False)

    print(f"Éxito: Se generaron {N_RECORDS} registros vinculados a ventas reales.")