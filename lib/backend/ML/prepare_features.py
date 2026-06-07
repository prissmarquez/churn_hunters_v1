import pandas as pd
import os

DATA_PATH = "lib/backend/data/processed/"

def load_all_clients():
    """Carga el dataset completo de todos los clientes preparados"""
    file_path = os.path.join(DATA_PATH, "X_all_clients_prepared.csv")
    df = pd.read_csv(file_path)
    return df

def encode_categoricals(df, cat_cols):
    """Codifica variables categóricas con one-hot encoding"""
    return pd.get_dummies(df, columns=cat_cols, drop_first=True)

def prepare_features():
    # Cargar todos los clientes
    df_all = load_all_clients()
    
    # Identificar variables categóricas
    cat_cols = ['territory_d', 'comercial_subchannel_d', 'rtm_customer_size_d']
    
    # Codificar variables categóricas
    df_all_encoded = encode_categoricals(df_all, cat_cols)
    
    # Guardar CSV final listo para predecir
    df_all_encoded.to_csv(os.path.join(DATA_PATH, "X_all_clients_encoded.csv"), index=False)
    print("[INFO] Features codificadas y guardadas en X_all_clients_encoded.csv")

if __name__ == "__main__":
    prepare_features()