import pandas as pd
import os
import joblib

DATA_PATH = "lib/backend/data/processed/"

def load_model():
    return joblib.load(os.path.join(DATA_PATH, "xgb_churn_model.pkl"))

def load_features():
    X_test = pd.read_csv(os.path.join(DATA_PATH, "X_test_prepared.csv"))
    return X_test

def generate_scores(model, X_test):
    # Guardamos customer_id antes de eliminar columnas no numéricas
    customer_ids = X_test['customer_id'] if 'customer_id' in X_test.columns else None
    X_test_num = X_test.select_dtypes(include=['int64','float64'])
    
    # Predecir probabilidad de churn
    probs = model.predict_proba(X_test_num)[:,1]
    
    df_scores = pd.DataFrame({
        'customer_id': customer_ids,
        'score': probs,
        'probabilidad_churn': probs
    })
    return df_scores

def add_top_features(df_scores, model, X_test, top_n=3):
    import numpy as np
    # Extraer top features globales
    X_test_num = X_test.select_dtypes(include=['int64','float64'])
    fi = model.feature_importances_
    top_idx = np.argsort(fi)[::-1][:top_n]
    top_features = X_test_num.columns[top_idx]
    
    df_scores['features_influyentes'] = [", ".join(top_features) for _ in range(len(df_scores))]
    return df_scores

def main():
    model = load_model()
    X_test = load_features()
    
    df_scores = generate_scores(model, X_test)
    df_scores = add_top_features(df_scores, model, X_test)
    
    # Guardar resultados finales
    df_scores.to_csv(os.path.join(DATA_PATH, "churn_scores_final.csv"), index=False)
    print("[INFO] Scores finales generados en churn_scores_final.csv")

if __name__ == "__main__":
    main()