"""
data_loader.py   (PERSONA B — correr UNA vez)
-----------------------------------------------------------
Punto 1 del backend: "Carga y procesamiento de datos".

Construye, por cada cliente, las features que tu API necesita para
EXPLICAR el riesgo y para FILTRAR. Esto NO depende de la Persona A:
sale directo de los CSV crudos que todos tienen.

  - de Clientes.csv  -> territorio, subcanal, tamaño (para filtrar)
  - de sales_*.csv   -> actividad reciente y tendencia (para explicar)
  - de Coolers.csv   -> coolers promedio (para explicar)

Salida -> data/customer_features.csv   (lo carga la API al arrancar)
Correr:  python data_loader.py
-----------------------------------------------------------
"""
from pathlib import Path
import pandas as pd

DATA = Path(__file__).resolve().parent.parent / "data"
SALES = "sales_churn_train.csv"   # historial con el que se explica el comportamiento


def construir_features_cliente():
    print("Cargando Clientes...")
    clientes = pd.read_csv(DATA / "Clientes.csv")

    print("Cargando Coolers...")
    coolers = pd.read_csv(DATA / "Coolers.csv")
    coolers_agg = (coolers.groupby("customer_id")
                   .agg(coolers_mean=("num_coolers", "mean"))
                   .reset_index())

    print("Cargando ventas y calculando actividad reciente...")
    ventas = pd.read_csv(DATA / SALES,
                         usecols=["customer_id", "calmonth", "num_transacciones"])
    ventas = ventas.sort_values(["customer_id", "calmonth"])

    g = ventas.groupby("customer_id")
    # actividad del ULTIMO mes registrado de cada cliente
    ult = g.tail(1).set_index("customer_id")["num_transacciones"].rename("trans_lag1")
    # promedio de los ultimos 3 y 6 meses + meses activos
    ult3 = ventas.groupby("customer_id").tail(3).groupby("customer_id")["num_transacciones"]
    roll3 = ult3.mean().rename("trans_roll3")
    activos = ult3.apply(lambda s: (s > 0).sum()).rename("meses_activos_3m")
    roll6 = (ventas.groupby("customer_id").tail(6)
             .groupby("customer_id")["num_transacciones"].mean().rename("trans_roll6"))

    feats = pd.concat([ult, roll3, roll6, activos], axis=1).reset_index()
    feats["trend"] = feats["trans_lag1"] - feats["trans_roll3"]

    # unir todo a nivel cliente
    out = (clientes
           .merge(feats, on="customer_id", how="left")
           .merge(coolers_agg, on="customer_id", how="left"))
    num = ["trans_lag1", "trans_roll3", "trans_roll6", "trend",
           "meses_activos_3m", "coolers_mean"]
    out[num] = out[num].fillna(0)

    out.to_csv(DATA / "customer_features.csv", index=False)
    print(f"customer_features.csv guardado: {len(out):,} clientes")
    return out


if __name__ == "__main__":
    construir_features_cliente()
