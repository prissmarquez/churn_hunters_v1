import pandas as pd
import os

RAW_DATA_PATH = "lib/backend/data/"
PROCESSED_DATA_PATH = "lib/backend/data/processed/"

def load_data(file_name):
    "Carga un archivo CSV desde data"
    file_path = os.path.join(RAW_DATA_PATH, file_name)
    df = pd.read_csv(file_path)
    return df

def clean_data(df):
    "Limpieza básica de datos"
    # 1. Eliminar duplicados
    df = df.drop_duplicates()
    
    # 2. Revisar nulos
    # Para variables numéricas: llenar con 0
    num_cols = df.select_dtypes(include=['float64', 'int64']).columns
    df[num_cols] = df[num_cols].fillna(0)
    
    # Para variables categóricas: llenar con 'Desconocido'
    cat_cols = df.select_dtypes(include=['object']).columns
    df[cat_cols] = df[cat_cols].fillna('Desconocido')
    
    # 3. Normalizar nombres de columnas (opcional)
    df.columns = [col.strip().lower().replace(" ", "_") for col in df.columns]
    
    return df

def save_processed(df, file_name):
    "Guardar archivo procesado en data/processed"
    os.makedirs(PROCESSED_DATA_PATH, exist_ok=True)
    file_path = os.path.join(PROCESSED_DATA_PATH, file_name)
    df.to_csv(file_path, index=False)
    print(f"[INFO] Archivo procesado guardado en: {file_path}")

# Ejecución rápida si se llama directamente
if __name__ == "__main__":
    for file_name in os.listdir(RAW_DATA_PATH):
        if file_name.endswith(".csv"):
            print(f"[INFO] Procesando archivo: {file_name}")
            df = load_data(file_name)
            df_clean = clean_data(df)
            save_processed(df_clean, file_name)