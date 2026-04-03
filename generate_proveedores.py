import pandas as pd
from faker import Faker
import random

fake = Faker("es_ES")

# Definimos el volumen solicitado
N_PROVEEDORES = 25 # Muestra de 800 OJO
random.seed(42) # Para que los resultados sean reproducibles

# Países específicos de la operación de RetailMax
paises_con_cd = ['Colombia', 'Mexico', 'Chile']
paises_sin_cd = ['Peru', 'Ecuador']
otros_paises = ['Estados Unidos', 'China', 'Brasil', 'España']

data_prov = []

for i in range(1, N_PROVEEDORES + 1):
    # Decidimos el origen con pesos (ej: 60% local, 30% regional, 10% internacional)
    categoria_origen = random.choices(
        ['local', 'regional', 'internacional'], 
        weights=[0.6, 0.3, 0.1]
    )[0]
    
    if categoria_origen == 'local':
        pais = random.choice(paises_con_cd)
        dias = random.randint(2, 7)
    elif categoria_origen == 'regional':
        pais = random.choice(paises_sin_cd)
        dias = random.randint(8, 15)
    else:
        pais = random.choice(otros_paises)
        dias = random.randint(20, 45)
        
    proveedor = {
        "id_proveedor": i,
        "razon_social": fake.company(),
        "pais_origen": pais,
        "tiempo_repo_dias": dias,
        "calificacion_calidad": round(random.uniform(3.0, 5.0), 1),
        "activo": random.choices([1, 0], weights=[0.9, 0.1])[0] # 90% activos
    }
    data_prov.append(proveedor)

# Crear el DataFrame y exportar a CSV
df_proveedores = pd.DataFrame(data_prov)

# RUTA CORRECTA (nivel proyecto)
import os

base_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(base_dir)
data_path = os.path.join(project_root, "data", "raw")

os.makedirs(data_path, exist_ok=True)

file_path = os.path.join(data_path, "MSTR_PROVEEDORES.csv")

df_proveedores.to_csv(file_path, index=False)

# Validación
print(df_proveedores.head())
print(df_proveedores.isnull().sum())

print(f" Archivo generado en: {file_path}")
print(f" Total proveedores: {len(df_proveedores)}")