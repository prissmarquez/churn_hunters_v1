import pandas as pd
import os

DATA_PATH = "lib/backend/data/processed/"

def load_data(file_name):
    path = os.path.join(DATA_PATH, file_name)
    return pd.read_csv(path)

# def merge_features(df_main, df_clientes, df_coolers):
#     """Merge de datos principales con clientes y coolers usando customer_id y calmonth"""
#     df = df_main.merge(df_clientes, on="customer_id", how="left")
#     df = df.merge(df_coolers, on=["customer_id", "calmonth"], how="left")
#     return df

def merge_features(df_main, df_clientes, df_coolers):
    """Merge de datos principales con clientes y coolers asegurando una fila por customer_id/calmonth"""
    
    # Clientes: una fila por customer_id
    df_clientes = df_clientes.drop_duplicates(subset=['customer_id'])
    
    # Coolers: una fila por customer_id/calmonth, agregando si hay duplicados
    df_coolers = df_coolers.groupby(['customer_id','calmonth'], as_index=False).agg({
        'num_coolers':'sum',
        'num_doors':'sum'
    })
    
    # Merge principal
    df = df_main.merge(df_clientes, on="customer_id", how="left")
    df = df.merge(df_coolers, on=["customer_id", "calmonth"], how="left")
    return df

def encode_categoricals(df, cat_cols):
    """Codifica variables categóricas con one-hot encoding"""
    return pd.get_dummies(df, columns=cat_cols, drop_first=True)

def prepare_and_save():
    # Cargar CSVs
    train_main = load_data("sales_churn_train.csv")
    test_main  = load_data("sales_churn_test.csv")
    clientes   = load_data("Clientes.csv")
    coolers    = load_data("Coolers.csv")
    
    # Separar target
    y_train = train_main['target']
    y_test  = test_main['target'] if 'target' in test_main.columns else None
    
    train_main = train_main.drop(columns=['target'])
    test_main  = test_main.drop(columns=['target'], errors='ignore')
    
    # Merge con clientes y coolers
    X_train = merge_features(train_main, clientes, coolers)
    X_test  = merge_features(test_main, clientes, coolers)
    
    # Identificar variables categóricas
    cat_cols = ['territory_d', 'comercial_subchannel_d', 'rtm_customer_size_d']
    
    # Codificar categóricas
    X_train = encode_categoricals(X_train, cat_cols)
    X_test  = encode_categoricals(X_test, cat_cols)
    
    # Guardar
    X_train.to_csv(os.path.join(DATA_PATH, "X_train_prepared.csv"), index=False)
    X_test.to_csv(os.path.join(DATA_PATH, "X_test_prepared.csv"), index=False)
    y_train.to_csv(os.path.join(DATA_PATH, "y_train.csv"), index=False)
    if y_test is not None:
        y_test.to_csv(os.path.join(DATA_PATH, "y_test.csv"), index=False)
    
    print("[INFO] Features preparadas y guardadas en data/processed/")

if __name__ == "__main__":
    prepare_and_save()