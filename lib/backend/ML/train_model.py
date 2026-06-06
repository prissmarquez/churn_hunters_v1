import pandas as pd
import os
import joblib
from xgboost import XGBClassifier
from sklearn.metrics import roc_auc_score, accuracy_score

DATA_PATH = "lib/backend/data/processed/"
MODEL_PATH = "lib/backend/data/processed/"

def load_prepared_data():
    X_train = pd.read_csv(os.path.join(DATA_PATH, "X_train_prepared.csv"))
    X_test  = pd.read_csv(os.path.join(DATA_PATH, "X_test_prepared.csv"))
    y_train = pd.read_csv(os.path.join(DATA_PATH, "y_train.csv")).squeeze()  # Convertir a Series
    try:
        y_test = pd.read_csv(os.path.join(DATA_PATH, "y_test.csv")).squeeze()
    except:
        y_test = None

    # Guardar IDs para resultados
    train_ids = X_train['customer_id'] if 'customer_id' in X_train.columns else None
    test_ids  = X_test['customer_id'] if 'customer_id' in X_test.columns else None

    # Eliminar columnas no numéricas antes de entrenar
    X_train = X_train.select_dtypes(include=['int64', 'float64'])
    X_test  = X_test.select_dtypes(include=['int64', 'float64'])

    return X_train, X_test, y_train, y_test, train_ids, test_ids

def train_xgboost(X_train, y_train):
    model = XGBClassifier(
        n_estimators=200,
        max_depth=5,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42,
        use_label_encoder=False,
        eval_metric='logloss'
    )
    model.fit(X_train, y_train)
    return model

def evaluate_model(model, X_test, y_test):
    if y_test is not None:
        y_prob = model.predict_proba(X_test)[:, 1]
        y_pred = model.predict(X_test)
        auc = roc_auc_score(y_test, y_prob)
        acc = accuracy_score(y_test, y_pred)
        print(f"[INFO] AUC: {auc:.4f}, Accuracy: {acc:.4f}")
    else:
        print("[WARN] No se encontró y_test, solo se entrenó el modelo.")

def save_model(model, file_name="xgb_churn_model.pkl"):
    path = os.path.join(MODEL_PATH, file_name)
    joblib.dump(model, path)
    print(f"[INFO] Modelo guardado en: {path}")

def main():
    X_train, X_test, y_train, y_test, train_ids, test_ids = load_prepared_data()
    print("[INFO] Datos cargados.")

    model = train_xgboost(X_train, y_train)
    print("[INFO] Modelo entrenado.")

    evaluate_model(model, X_test, y_test)
    save_model(model)

    # Guardar scores si y_test existe
    if y_test is not None:
        y_prob = model.predict_proba(X_test)[:, 1]
        results_df = pd.DataFrame({
            'customer_id': test_ids,
            'score': y_prob
        })
        results_df.to_csv(os.path.join(DATA_PATH, "churn_scores.csv"), index=False)
        print("[INFO] Scores de churn guardados en churn_scores.csv")

if __name__ == "__main__":
    main()