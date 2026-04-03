import pandas as pd
from faker import Faker
import random
import os

fake = Faker("es_ES")

N_TIENDAS = 22 # Muestra de 150
random.seed(42)

# Países
paises = {
    1: "Colombia",
    2: "México",
    3: "Chile",
    4: "Perú",
    5: "Ecuador"
}

# Ciudades con relación a país
ciudades = {
    1: ("Bogotá", 1),
    2: ("Medellín", 1),
    3: ("Cali", 1),
    4: ("CDMX", 2),
    5: ("Monterrey", 2),
    6: ("Guadalajara", 2),
    7: ("Santiago", 3),
    8: ("Lima", 4),
    9: ("Quito", 5),
    10: ("Guayaquil", 5),
    11: ("Cuenca", 5)
}

tipos_tienda = ["hipermercado", "supermercado", "conveniencia"]

data = []

for i in range(1, N_TIENDAS + 1):
    
    tipo = random.choices(
        tipos_tienda,
        weights=[0.2, 0.5, 0.3]
    )[0]
    
    # Tamaño según tipo
    if tipo == "hipermercado":
        metros = random.randint(1000, 5000)
    elif tipo == "supermercado":
        metros = random.randint(300, 1500)
    else:
        metros = random.randint(50, 300)
    
    id_ciudad = random.choice(list(ciudades.keys()))
    nombre_ciudad, id_pais = ciudades[id_ciudad]
    
    tienda = {
        "id_tienda": i,
        "nom_tienda": f"RetailMax {nombre_ciudad} {i}",
        "tipo_tienda": tipo,
        "id_ciudad": id_ciudad,
        "id_pais": id_pais,
        "metros_cuadrados": metros,
        "activo": random.choices([1, 0], weights=[0.95, 0.05])[0],
        "fec_apertura": fake.date_between(start_date='-26y', end_date='today')
    }
    
    data.append(tienda)

tipos_digital = ["marketplace", "ecommerce"]

for i in range(N_TIENDAS + 1,N_TIENDAS + 4): # +11
    
    tipo = random.choices(tipos_digital)
    id_ciudad = random.choice([1,4])
    nombre_ciudad, id_pais = ciudades[id_ciudad]
    
    tienda = {
        "id_tienda": i,
        "nom_tienda": f"RetailMax {nombre_ciudad} {i}",
        "tipo_tienda": tipo,
        "id_ciudad": id_ciudad,
        "id_pais": id_pais,
        "metros_cuadrados": None,
        "activo": random.choices([1, 0], weights=[0.95, 0.05])[0],
        "fec_apertura": fake.date_between(start_date='-7y', end_date='today')
    }
    
    data.append(tienda)


df_tiendas = pd.DataFrame(data)

# Rutas correctas
base_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(base_dir)
data_path = os.path.join(project_root, "data", "raw")

os.makedirs(data_path, exist_ok=True)

file_path = os.path.join(data_path, "MSTR_TIENDAS.csv")

df_tiendas.to_csv(file_path, index=False)

# Validación
print(df_tiendas.head())
print(df_tiendas.isnull().sum())

print(df_tiendas.head())
print("-" * 50)
print("Distribución por formato:")
print(df_tiendas['tipo_tienda'].value_counts())
print("-" * 50)
print(f"Éxito: Se generaron {len(df_tiendas)} registros en {file_path}")