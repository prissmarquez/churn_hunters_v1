import pandas as pd
import os
import matplotlib.pyplot as plt

DATA_PATH = "lib/backend/data/processed/"
FILE_NAME = "churn_scores_final.csv"

# Cargar datos
df = pd.read_csv(os.path.join(DATA_PATH, FILE_NAME))

# Cantidad total de clientes
total_clients = df['customer_id'].nunique()

# Clientes con score >= 0.8 (alto riesgo)
high_risk_threshold = 0.8
high_risk = df[df['score'] >= high_risk_threshold]
num_high_risk = high_risk['customer_id'].nunique()
percent_high_risk = num_high_risk / total_clients * 100

print(f"Cantidad total de clientes: {total_clients}")
print(f"Clientes en alto riesgo (score ≥ {high_risk_threshold}): {num_high_risk}")
print(f"Porcentaje de clientes en alto riesgo: {percent_high_risk:.2f}%")

# Histograma general de scores
plt.figure(figsize=(8,5))
plt.hist(df['score'], bins=50, color='skyblue', edgecolor='black')
plt.title('Distribución de la Probabilidad de Churn')
plt.xlabel('Probabilidad de Churn')
plt.ylabel('Cantidad de Clientes')
plt.grid(axis='y', alpha=0.75)
plt.axvline(high_risk_threshold, color='red', linestyle='--', label=f'Umbral {high_risk_threshold}')
plt.legend()
plt.show()