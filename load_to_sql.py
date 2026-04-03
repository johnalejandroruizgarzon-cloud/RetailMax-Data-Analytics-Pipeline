import pandas as pd
import urllib.parse
from sqlalchemy import create_engine, event
import os

# --- CONFIGURACIÓN ---
server = 'sql-rtlmxjr26-dev.database.windows.net' 
database = 'RetailMaxDB'
username = 'adminretail'
password = 'SuperPassword2026!'
driver = '{ODBC Driver 18 for SQL Server}'
data_path = r"C:\Users\ALEJANDRO\Retail Project\data\raw"

archivos_a_cargar = {
    "MSTR_TIENDAS.csv": "MSTR_TIENDAS",
    "MSTR_ARTICULOS.csv": "MSTR_ARTICULOS",
    "MSTR_PROVEEDORES.csv": "MSTR_PROVEEDORES",
    "TRANS_VENTAS.csv": "TRANS_VENTAS",
    "CRM_MIEMBROS.csv": "CRM_MIEMBROS",
    "INV_STOCK_DIARIO.csv": "INV_STOCK_DIARIO",
    "POST_DEVOLUCIONES.csv": "POST_DEVOLUCIONES"
}

print("Iniciando conexión con el Driver 18...")

try:
    conn_str = (
        f"DRIVER={driver};SERVER={server};DATABASE={database};"
        f"UID={username};PWD={password};Encrypt=yes;TrustServerCertificate=yes;"
    )
    params = urllib.parse.quote_plus(conn_str)
    engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

    # ACTIVAR FAST_EXECUTEMANY (Esto es lo que da velocidad real)
    @event.listens_for(engine, "before_cursor_execute")
    def receive_before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
        if executemany:
            cursor.fast_executemany = True

    print("¡Conexión exitosa a Azure SQL! 🚀\n")

    for archivo, nombre_tabla in archivos_a_cargar.items():
        ruta_completa = os.path.join(data_path, archivo)
        
        if os.path.exists(ruta_completa):
            print(f"Cargando {archivo} en la tabla {nombre_tabla}...")
            
            # Leemos por chunks para no saturar la RAM
            # Aumentamos el chunksize a 10,000 para aprovechar fast_executemany
            reader = pd.read_csv(ruta_completa, chunksize=10000)
            
            for i, chunk in enumerate(reader):
                # El primer chunk 'replace' (crea la tabla), los demás 'append' (suman datos)
                modo = 'replace' if i == 0 else 'append'
                
                # IMPORTANTE: No uses method='multi' con fast_executemany, 
                # es más lento y causa el error de parámetros que viste antes.
                chunk.to_sql(name=nombre_tabla, con=engine, if_exists=modo, index=False)
                
                print(f"  --> Procesado bloque {i+1}...")

            print(f"✅ Tabla {nombre_tabla} cargada exitosamente.\n")
        else:
            print(f"⚠️ Advertencia: No se encontró {archivo}\n")

    print("-" * 50)
    print("¡PROCESO FINALIZADO CON ÉXITO! La Fase 1 está lista.")

except Exception as e:
    print(f"❌ Error durante el proceso: {e}")