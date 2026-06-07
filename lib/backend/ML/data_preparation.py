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
    
    # 3. Normalizar nombres de columnas
    df.columns = [col.strip().lower().replace(" ", "_") for col in df.columns]
    
    return df

def merge_all_clients(clientes, sales, coolers):
    "Merge de todos los clientes con sus features sin duplicados"
    clientes = clientes.drop_duplicates(subset=['customer_id'])

    # Coolers: agrupar por cliente y mes
    coolers = coolers.groupby(['customer_id','calmonth'], as_index=False).agg({
        'num_coolers':'sum',
        'num_doors':'sum'
    })

    # Sales: agrupar por cliente y mes
    sales = sales.groupby(['customer_id','calmonth'], as_index=False).agg({
        'num_transacciones':'sum',
        'uni_boxes_sold_m':'sum'
    })

    # Merge todo
    df_all = clientes.merge(sales, on='customer_id', how='left')
    df_all = df_all.merge(coolers, on=['customer_id','calmonth'], how='left')
    return df_all

def save_processed(df, file_name):
    "Guardar archivo procesado en data/processed"
    os.makedirs(PROCESSED_DATA_PATH, exist_ok=True)
    file_path = os.path.join(PROCESSED_DATA_PATH, file_name)
    df.to_csv(file_path, index=False)
    print(f"[INFO] Archivo procesado guardado en: {file_path}")

if __name__ == "__main__":
    # Cargar CSVs necesarios
    clientes = load_data("Clientes.csv")
    sales    = load_data("sales_churn_train.csv")
    coolers  = load_data("Coolers.csv")
    
    # Limpiar cada dataframe
    clientes_clean = clean_data(clientes)
    sales_clean    = clean_data(sales)
    coolers_clean  = clean_data(coolers)
    
    # Merge de todos los clientes reales
    all_clients_df = merge_all_clients(clientes_clean, sales_clean, coolers_clean)
    
    # Guardar dataset completo listo para ML
    save_processed(all_clients_df, "X_all_clients_prepared.csv")