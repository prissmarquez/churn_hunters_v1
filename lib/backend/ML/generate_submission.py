"""
Genera preds_submission.csv con predicciones 0/1 del modelo XGBoost entrenado.

Estrategia:
  1. Usar churn_scores_final.csv (salida directa del modelo) para los clientes que ya
     tienen score calculado (198,403 de 199,923).
  2. Para los 1,520 clientes restantes que no estaban en el score, predecir con el
     modelo usando sales_churn_test.csv + Clientes.csv + Coolers.csv.
"""

import pandas as pd
import numpy as np
import joblib
import os

RAW_PATH = "lib/backend/data/"
MODEL_PATH = "lib/backend/data/processed/"
THRESHOLD = 0.5


def build_fallback_features(missing_ids):
    """Construye features para clientes que no están en churn_scores_final."""
    sales_test = pd.read_csv(os.path.join(RAW_PATH, "sales_churn_test.csv"))
    clientes = pd.read_csv(os.path.join(RAW_PATH, "Clientes.csv"))
    coolers = pd.read_csv(os.path.join(RAW_PATH, "Coolers.csv"))

    sales_test.columns = [c.strip().lower().replace(" ", "_") for c in sales_test.columns]
    clientes.columns = [c.strip().lower().replace(" ", "_") for c in clientes.columns]
    coolers.columns = [c.strip().lower().replace(" ", "_") for c in coolers.columns]

    sales_test = sales_test[sales_test["customer_id"].isin(missing_ids)]

    coolers_agg = coolers.groupby(["customer_id", "calmonth"], as_index=False).agg(
        num_coolers=("num_coolers", "sum"),
        num_doors=("num_doors", "sum"),
    )
    sales_agg = sales_test.groupby(["customer_id", "calmonth"], as_index=False).agg(
        num_transacciones=("num_transacciones", "sum"),
        uni_boxes_sold_m=("uni_boxes_sold_m", "sum"),
    )

    df = sales_agg.merge(clientes, on="customer_id", how="left")
    df = df.merge(coolers_agg, on=["customer_id", "calmonth"], how="left")

    num_cols = df.select_dtypes(include=["float64", "int64"]).columns
    df[num_cols] = df[num_cols].fillna(0)
    cat_cols_obj = df.select_dtypes(include=["object"]).columns.difference(["customer_id"])
    df[cat_cols_obj] = df[cat_cols_obj].fillna("Desconocido")

    df_latest = df.sort_values("calmonth").groupby("customer_id").last().reset_index()
    return df_latest


def encode_like_training(df, feature_cols):
    cat_cols = ["territory_d", "comercial_subchannel_d", "rtm_customer_size_d"]
    existing_cat = [c for c in cat_cols if c in df.columns]
    df_enc = pd.get_dummies(df, columns=existing_cat, drop_first=True)
    return df_enc.reindex(columns=feature_cols, fill_value=0)


def main():
    # 1. Cargar el submission base
    submission = pd.read_csv(os.path.join(RAW_PATH, "preds_submission.csv"))
    print(f"[INFO] Clientes en submission: {len(submission)}")

    # 2. Fuente principal: churn_scores_final.csv (ya es output del modelo XGBoost)
    scores = pd.read_csv(os.path.join(MODEL_PATH, "churn_scores_final.csv"))
    score_map = dict(zip(scores["customer_id"], scores["probabilidad_churn"]))
    print(f"[INFO] Clientes con score del modelo: {len(scores)}")

    # 3. Identificar clientes sin score
    missing_ids = set(submission["customer_id"]) - set(score_map.keys())
    print(f"[INFO] Clientes sin score (fallback): {len(missing_ids)}")

    # 4. Predecir los clientes faltantes con el modelo directamente
    fallback_map = {}
    if missing_ids:
        print("[INFO] Cargando modelo para clientes faltantes...")
        model = joblib.load(os.path.join(MODEL_PATH, "xgb_churn_model.pkl"))
        feature_cols = joblib.load(os.path.join(MODEL_PATH, "feature_cols.pkl"))

        df_fallback = build_fallback_features(missing_ids)
        X_fallback = encode_like_training(df_fallback, feature_cols)
        probs = model.predict_proba(X_fallback)[:, 1]
        fallback_map = dict(zip(df_fallback["customer_id"].values, probs))
        print(f"[INFO] Fallback calculado para {len(fallback_map)} clientes")

    # 5. Llenar submission: primero score del modelo, luego fallback, luego 0
    combined_map = {**fallback_map, **score_map}  # score_map tiene prioridad
    submission["target"] = submission["customer_id"].map(combined_map).fillna(0).round(6)

    out_path = os.path.join(RAW_PATH, "preds_submission.csv")
    submission.to_csv(out_path, index=False)

    print(f"\n[INFO] Guardado: {out_path}")
    print(f"[INFO] Total predicciones: {len(submission)}")
    print(f"[INFO] Probabilidad promedio: {submission['target'].mean():.4f}")
    print(f"[INFO] Clientes prob >= 0.80: {(submission['target'] >= 0.80).sum()}")
    print(f"[INFO] Clientes prob >= 0.50: {(submission['target'] >= 0.50).sum()}")
    print(f"[INFO] Clientes prob < 0.10:  {(submission['target'] < 0.10).sum()}")
    print(f"[INFO] Clientes con score directo del modelo: {submission['customer_id'].isin(score_map).sum()}")
    print(f"[INFO] Clientes con prediccion fallback: {submission['customer_id'].isin(fallback_map).sum()}")


if __name__ == "__main__":
    main()
