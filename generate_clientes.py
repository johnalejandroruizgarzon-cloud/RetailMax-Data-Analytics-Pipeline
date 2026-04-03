import pandas as pd
from faker import Faker
import random
import os

fake = Faker("es_ES")

# 1. Configuración Inicial
N_REGISTROS = 500 # Muestra de 50.000 
random.seed(42)

# --- MEJORA TÉCNICA: Generación de IDs Únicos de 6 a 9 dígitos ---
# Usamos un set para garantizar que no se repitan IDs en la muestra
ids_unicos = set()
while len(ids_unicos) < N_REGISTROS:
    # Rango desde 100.000 (6 dígitos) hasta 999.999.999 (9 dígitos)
    ids_unicos.add(random.randint(100000, 999999999))

# Convertimos a lista para poder iterar ordenadamente si se desea
lista_ids = list(ids_unicos)

# Catálogos
ciudades = {1: "Bogotá", 2: "Medellín", 3: "Cali", 4: "CDMX", 5: "Monterrey", 
            6: "Guadalajara", 7: "Santiago de Chile", 8: "Lima", 9: "Quito", 
            10: "Guayaquil", 11: "Cuenca"}
generos = ['M', 'F', None]
rangos_edad = ['18-25', '26-35', '36-45', '46-60', '60+']
canales = ['online', 'tienda']

data = []

# 2. Bucle de Generación
for idx in range(N_REGISTROS):
    fecha_reg = fake.date_between(start_date='-10y', end_date='today')
    id_ciudad = random.choice(list(ciudades.keys()))
    
    if random.random() < 0.8:
        fec_ultima = fake.date_between(start_date=fecha_reg, end_date='today')
    else:
        fec_ultima = None

    registro = {
        # Usamos el ID de nuestra lista de IDs largos y únicos
        "id_miembro": lista_ids[idx], 
        "fec_registro": fecha_reg,
        "id_ciudad": id_ciudad,
        "genero": random.choice(generos),
        "rango_edad": random.choice(rangos_edad),
        "canal_pref": random.choice(canales),
        "activo": random.choices([1, 0], weights=[0.85, 0.15])[0],
        "fec_ultima_compra": fec_ultima
    }
    data.append(registro)

# 3. Crear el DataFrame
df_miembros = pd.DataFrame(data)

# Asegurar que el ID sea entero para evitar .0 en el CSV
df_miembros['id_miembro'] = df_miembros['id_miembro'].astype(int)

# 4. Exportación
base_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(base_dir)
data_path = os.path.join(project_root, "data", "raw")
os.makedirs(data_path, exist_ok=True)

file_path = os.path.join(data_path, "CRM_MIEMBROS.csv")
df_miembros.to_csv(file_path, index=False)

# Validación
print("--- Muestra de Miembros con IDs Largos ---")
print(df_miembros[['id_miembro', 'genero', 'rango_edad']].head())
print(f"\nÉxito: Archivo generado con {len(df_miembros)} registros únicos.")