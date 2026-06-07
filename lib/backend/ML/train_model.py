import pandas as pd
import os
import joblib
from xgboost import XGBClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import roc_auc_score, classification_report, confusion_matrix

DATA_PATH = "lib/backend/data/processed/"
RAW_PATH = "lib/backend/data/"
MODEL_PATH = "lib/backend/data/processed/"

# El target real lo construimos como churn del MES SIGUIENTE -> ya no es feature
DROP_COLS = ['customer_id', 'calmonth', 'target', 'target_next']


def load_train_data():
    """Features del mes t -> predicen churn del mes t+1 (sin leakage)."""
    X_all = pd.read_csv(os.path.join(DATA_PATH, "X_all_clients_encoded.csv"))

    sales = pd.read_csv(os.path.join(RAW_PATH, "sales_churn_train.csv"))
    sales = sales[['customer_id', 'calmonth', 'target']].drop_duplicates()

    # Ordenar por cliente y mes para poder desplazar el target
    sales = sales.sort_values(['customer_id', 'calmonth'])
    # target_next = el churn del MES SIGUIENTE del mismo cliente
    sales['target_next'] = sales.groupby('customer_id')['target'].shift(-1)
    # El ultimo mes de cada cliente no tiene "siguiente" -> se descarta
    sales = sales.dropna(subset=['target_next'])
    sales['target_next'] = sales['target_next'].astype(int)

    # Pegar el target del mes siguiente a las features del mes actual
    df_train = X_all.merge(
        sales[['customer_id', 'calmonth', 'target_next']],
        on=['customer_id', 'calmonth'], how='inner'
    )

    y = df_train['target_next']
    feature_cols = [c for c in df_train.columns if c not in DROP_COLS]
    X = df_train[feature_cols]
    return X, y, feature_cols


def train_xgboost(X_train, y_train):
    n_pos = int((y_train == 1).sum())
    n_neg = int((y_train == 0).sum())
    scale = (n_neg / n_pos) if n_pos > 0 else 1.0
    print(f"[INFO] positivos={n_pos}  negativos={n_neg}  scale_pos_weight={scale:.2f}")

    model = XGBClassifier(
        n_estimators=200,
        max_depth=5,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        scale_pos_weight=scale,
        random_state=42,
        eval_metric='logloss',
        n_jobs=-1,
    )
    model.fit(X_train, y_train)
    return model


def evaluar(model, X_test, y_test):
    probs = model.predict_proba(X_test)[:, 1]
    preds = (probs >= 0.5).astype(int)
    print(f"\n[EVAL] AUC = {roc_auc_score(y_test, probs):.3f}")
    print("[EVAL] Matriz de confusion (umbral 0.5):")
    print(confusion_matrix(y_test, preds))
    print("[EVAL] Reporte de clasificacion:")
    print(classification_report(y_test, preds, digits=3))
    print(f"[EVAL] Clientes en test con prob >= 0.80: "
          f"{(probs >= 0.80).sum()} de {len(probs)}")


def save_model(model, feature_cols, file_name="xgb_churn_model.pkl"):
    os.makedirs(MODEL_PATH, exist_ok=True)
    joblib.dump(model, os.path.join(MODEL_PATH, file_name))
    joblib.dump(feature_cols, os.path.join(MODEL_PATH, "feature_cols.pkl"))
    print(f"[INFO] Modelo guardado en: {file_name}")
    print(f"[INFO] {len(feature_cols)} features guardadas en feature_cols.pkl")


def main():
    X, y, feature_cols = load_train_data()
    print(f"[INFO] Datos de entrenamiento: {X.shape[0]} filas, {X.shape[1]} features")

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    model = train_xgboost(X_train, y_train)
    print("[INFO] Modelo entrenado.")
    evaluar(model, X_test, y_test)
    save_model(model, feature_cols)


if __name__ == "__main__":
    main()