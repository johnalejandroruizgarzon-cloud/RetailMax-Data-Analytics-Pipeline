import pandas as pd
import random
import os
from faker import Faker

# Inicialización
fake = Faker()
random.seed(42)
N_ARTICULOS = 100 #Muestra de 5000

# 1. Definición de la Jerarquía de Categorías (N1 -> N2 -> N3)
categorias_map = {
    "Alimentos y bebidas": {
        "Lácteos": ["Leche Entera", "Yogurt Natural", "Queso Campesino"],
        "Snacks": ["Papas Fritas", "Galletas Dulces", "Frutos Secos Mix"]
    },
    "Cuidado personal e higiene": {
        "Cuidado Capilar": ["Shampoo Anticaspa", "Acondicionador Brillo", "Crema de Peinar"],
        "Cuidado Oral": ["Crema Dental", "Enjuague Bucal", "Seda Dental"]
    },
    "Hogar y limpieza": {
        "Lavandería": ["Detergente Líquido", "Suavizante Telas", "Quitamanchas"],
        "Cocina": ["Lavaloza", "Esponja Multiuso", "Desengrasante"]
    },
    "Electrónica y tecnología": {
        "Computación": ["Mouse Inalámbrico", "Teclado Mecánico", "Cargador Universal"],
        "Audio": ["Audífonos Bluetooth", "Parlante Portátil", "Cable Auxiliar"]
    },
    "Ropa y calzado básico": {
        "Hombre": ["Camiseta Algodón", "Medias Sport", "Bóxer Classic"],
        "Mujer": ["Leggings Yoga", "Top Deportivo", "Baletas Básicas"]
    },
    "Bebes y maternidad": {
        "Higiene": ["Pañales Etapa 3", "Pañitos Húmedos", "Crema Antipañalitis"],
        "Alimentación": ["Tetero Ergonómico", "Chupo Silicona", "Babero Impermeable"]
    }
}

# 2. Configuración de Precios por Macro Categoría (N1)
rangos_precios_n1 = {
    "Alimentos y bebidas": (1500, 45000),
    "Cuidado personal e higiene": (3500, 120000),
    "Hogar y limpieza": (4000, 180000),
    "Electrónica y tecnología": (25000, 1500000),
    "Ropa y calzado básico": (12000, 250000),
    "Bebes y maternidad": (9000, 300000)
}

# --- Mapeo de IDs ---

# Nivel 1
n1_nombres = list(categorias_map.keys())
n1_id_map = {nombre: i + 1 for i, nombre in enumerate(n1_nombres)}

# Nivel 2 (Extraemos todos los N2 únicos de todos los N1)
n2_nombres = []
for n1 in categorias_map:
    n2_nombres.extend(categorias_map[n1].keys())
n2_id_map = {nombre: i + 1 for i, nombre in enumerate(n2_nombres)}

# Nivel 3 (Extraemos todos los N3 únicos)
n3_nombres = []
for n1 in categorias_map:
    for n2 in categorias_map[n1]:
        n3_nombres.extend(categorias_map[n1][n2])
n3_id_map = {nombre: i + 1 for i, nombre in enumerate(n3_nombres)}

data_art = []

for i in range(1, N_ARTICULOS + 1):
    # Selección jerárquica de categorías
    n1 = random.choice(list(categorias_map.keys()))
    n2 = random.choice(list(categorias_map[n1].keys()))
    n3 = random.choice(categorias_map[n1][n2])
    
    # Lógica de precio basada en N1
    min_p, max_p = rangos_precios_n1[n1]
    precio = round(random.uniform(min_p, max_p), 2)
    
    # Creación del registro
    articulo = {
        "art_id": i,
        "cod_barra": fake.ean13(),
        "desc_art": f"{n3} {fake.word().capitalize()}",
        
        # Guardamos el ID numérico en lugar del texto
        "id_categ_n1": n1_id_map[n1],
        "id_categ_n2": n2_id_map[n2],
        "id_categ_n3": n3_id_map[n3],
        
        "id_proveedor": random.randint(1, 25), #Muestra de 800 OJO!
        "precio_lista": precio,
        "peso_kg": round(random.uniform(0.1, 15.0), 2),
        "unid_medida": "KG",
        "activo": random.choices([1, 0], weights=[0.95, 0.05])[0],
        "fec_alta": fake.date_between(start_date='-12y', end_date='today')
    }
    data_art.append(articulo)

# 3. Gestión de Rutas y Exportación
df_articulos = pd.DataFrame(data_art)

base_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(base_dir)
data_path = os.path.join(project_root, "data", "raw")
os.makedirs(data_path, exist_ok=True)

file_path = os.path.join(data_path, "MSTR_ARTICULOS.csv")
df_articulos.to_csv(file_path, index=False)

# Validación
print(df_articulos.head())
print(df_articulos.isnull().sum())
print(f"Éxito: Se generaron {len(df_articulos)} registros en {file_path}")