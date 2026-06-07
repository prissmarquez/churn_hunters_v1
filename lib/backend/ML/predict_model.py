import pandas as pd
import os
import joblib
import numpy as np
import shap

DATA_PATH = "lib/backend/data/processed/"
MODEL_FILE = "xgb_churn_model.pkl"
OUTPUT_FILE = "churn_scores_final.csv"

UMBRAL_ALTO = 0.80
UMBRAL_MEDIO = 0.50
TOP_N = 3


def load_model():
    model = joblib.load(os.path.join(DATA_PATH, MODEL_FILE))
    print("[INFO] Modelo cargado:", MODEL_FILE)
    return model


def load_feature_cols():
    return joblib.load(os.path.join(DATA_PATH, "feature_cols.pkl"))


def load_features():
    return pd.read_csv(os.path.join(DATA_PATH, "X_all_clients_encoded.csv"))


def categorizar(prob):
    if prob >= UMBRAL_ALTO:
        return "alto"
    elif prob >= UMBRAL_MEDIO:
        return "medio"
    return "bajo"


def main():
    model = load_model()
    feature_cols = load_feature_cols()
    X_all = load_features()

    X_features = X_all.reindex(columns=feature_cols, fill_value=0)

    df = pd.DataFrame({
        'customer_id': X_all['customer_id'].values,
        'calmonth': X_all['calmonth'].values,
    })
    df['_row'] = np.arange(len(df))

    # Descartar clientes sin historial de ventas (calmonth vacio) -> no se pueden puntuar
    antes = len(df)
    df = df.dropna(subset=['calmonth'])
    print(f"[INFO] Filas con historial valido: {len(df)} (se descartaron {antes - len(df)})")

    # 1) Nos quedamos con el MES MAS RECIENTE de cada cliente (su dato actual)
    idx = df.groupby('customer_id')['calmonth'].idxmax()
    df_sel = df.loc[idx].reset_index(drop=True)
    print(f"[INFO] Clientes unicos: {len(df_sel)}")

    rows = df_sel['_row'].values
    X_sel = X_features.iloc[rows]

    # 2) Probabilidad de churn del PROXIMO mes
    print("[INFO] Calculando probabilidades...")
    probs = model.predict_proba(X_sel)[:, 1]
    df_sel['probabilidad_churn'] = probs

    # 3) SHAP solo sobre esas filas
    print(f"[INFO] Calculando SHAP para {len(X_sel)} filas...")
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X_sel)
    if isinstance(shap_values, list):
        shap_values = shap_values[1]

    feature_names = np.array(feature_cols)
    top_feats = []
    for i in range(len(X_sel)):
        contribs = shap_values[i]
        top_idx = np.argsort(np.abs(contribs))[::-1][:TOP_N]
        top_feats.append(", ".join(feature_names[top_idx]))

    df_sel['features_influyentes'] = top_feats
    df_sel['nivel_riesgo'] = df_sel['probabilidad_churn'].apply(categorizar)
    df_sel['score'] = df_sel['probabilidad_churn']

    out = df_sel[['customer_id', 'score', 'probabilidad_churn',
                  'nivel_riesgo', 'features_influyentes']]
    out.to_csv(os.path.join(DATA_PATH, OUTPUT_FILE), index=False)
    print("[INFO] Guardado en:", OUTPUT_FILE)
    print("[INFO] Riesgo ALTO (>=80%):", (out['nivel_riesgo'] == 'alto').sum())


if __name__ == "__main__":
    main()
    