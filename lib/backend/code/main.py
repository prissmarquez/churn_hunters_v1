import pandas as pd

DATA = "lib/backend/data/processed/"
RAW = "lib/backend/data/"

scores = pd.read_csv(DATA + "churn_scores_final.csv")
sales = pd.read_csv(RAW + "sales_churn_train.csv",
                    usecols=['customer_id', 'calmonth',
                             'uni_boxes_sold_m', 'num_transacciones'])


def historial(cid):
    h = sales[sales.customer_id == cid].sort_values('calmonth')
    return h[['calmonth', 'uni_boxes_sold_m', 'num_transacciones']]


# 1) Distribucion de niveles de riesgo
print("=== Distribucion de niveles de riesgo ===")
dist = scores['nivel_riesgo'].value_counts()
for nivel, n in dist.items():
    print(f"{nivel:6s}: {n:7d}  ({n / len(scores) * 100:.1f}%)")

print("\n=== Estadisticas de la probabilidad de churn ===")
print(scores['probabilidad_churn'].describe())

# 2) Clientes de ALTO riesgo: deberian venir cayendo o ya inactivos
print("\n========== TOP 3 ALTO RIESGO (deben venir cayendo) ==========")
altos = scores.sort_values('probabilidad_churn', ascending=False).head(3)
for _, r in altos.iterrows():
    print(f"\n>> Cliente {r.customer_id} | riesgo {r.probabilidad_churn:.1%} "
          f"| drivers: {r.features_influyentes}")
    print(historial(r.customer_id).to_string(index=False))

# 3) Clientes de BAJO riesgo: deberian comprar estable
print("\n========== TOP 3 BAJO RIESGO (deben comprar estable) ==========")
bajos = scores.sort_values('probabilidad_churn', ascending=True).head(3)
for _, r in bajos.iterrows():
    print(f"\n>> Cliente {r.customer_id} | riesgo {r.probabilidad_churn:.1%} "
          f"| drivers: {r.features_influyentes}")
    print(historial(r.customer_id).to_string(index=False))