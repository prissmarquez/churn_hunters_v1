"""
build_features.py   (PERSONA B)  -- correr UNA vez
-----------------------------------------------------------
Tu pipeline de ML ahora entrega un PANEL mensual:
  data/processed/X_all_clients_prepared.csv
  (1 fila por cliente por mes: segmentos + num_transacciones,
   uni_boxes_sold_m, num_coolers, num_doors, calmonth)

Pero la API y Ia.py necesitan un RESUMEN por cliente
(trans_lag1, trans_roll3, ...). Este script colapsa el panel
a 1 fila por cliente y guarda:

  data/customer_features.csv

Correr (con el venv activo, desde la carpeta Api/):
  python build_features.py
-----------------------------------------------------------
"""
from pathlib import Path
import pandas as pd

DATA = Path(__file__).resolve().parent.parent / "data"
PANEL = DATA / "processed" / "X_all_clients_prepared.csv"
SALIDA = DATA / "customer_features.csv"

# solo leemos lo que necesitamos (el panel pesa cientos de MB)
USECOLS = ["customer_id", "territory_d", "comercial_subchannel_d",
           "rtm_customer_size_d", "calmonth", "num_transacciones",
           "uni_boxes_sold_m", "num_coolers", "num_doors"]


def main():
    if not PANEL.exists():
        raise SystemExit(f"No encuentro el panel:\n  {PANEL}\n"
                         "Revisa que exista X_all_clients_prepared.csv en data/processed/")

    print(f"[1/4] Leyendo panel: {PANEL.name} (puede tardar, es grande)...")
    df = pd.read_csv(PANEL, usecols=USECOLS)
    print(f"      {len(df):,} filas (cliente-mes), {df['customer_id'].nunique():,} clientes únicos")

    # ordenar por cliente y mes DESCENDENTE -> rk=0 es el mes más reciente
    print("[2/4] Ordenando y rankeando meses por cliente...")
    df = df.sort_values(["customer_id", "calmonth"], ascending=[True, False])
    df["rk"] = df.groupby("customer_id").cumcount()   # 0 = mes más reciente

    g = df.groupby("customer_id", sort=False)

    print("[3/4] Calculando features resumidas...")
    ult3  = df[df["rk"] <= 2]      # últimos 3 meses
    ult6  = df[df["rk"] <= 5]      # últimos 6 meses
    prev3 = df[(df["rk"] >= 3) & (df["rk"] <= 5)]  # los 3 meses anteriores a esos

    out = pd.DataFrame(index=g.size().index)

    # segmentos: el valor del mes más reciente
    recientes = df[df["rk"] == 0].set_index("customer_id")
    out["territory_d"]            = recientes["territory_d"]
    out["comercial_subchannel_d"] = recientes["comercial_subchannel_d"]
    out["rtm_customer_size_d"]    = recientes["rtm_customer_size_d"]

    # actividad del último mes (lag1)
    out["trans_lag1"] = recientes["num_transacciones"]
    out["boxes_lag1"] = recientes["uni_boxes_sold_m"]

    # promedios móviles
    out["trans_roll3"] = ult3.groupby("customer_id")["num_transacciones"].mean()
    out["boxes_roll3"] = ult3.groupby("customer_id")["uni_boxes_sold_m"].mean()
    out["trans_roll6"] = ult6.groupby("customer_id")["num_transacciones"].mean()
    out["boxes_roll6"] = ult6.groupby("customer_id")["uni_boxes_sold_m"].mean()

    # tendencia: media últimos 3m - media 3m anteriores (negativo = a la baja)
    media_prev3 = prev3.groupby("customer_id")["num_transacciones"].mean()
    out["trend"] = (out["trans_roll3"] - media_prev3).fillna(0)

    # meses activos en los últimos 3 (con al menos 1 transacción)
    out["meses_activos_3m"] = (ult3.assign(act=ult3["num_transacciones"] > 0)
                               .groupby("customer_id")["act"].sum())

    # antigüedad = # de meses con registro
    out["antiguedad"] = g.size()

    # coolers / puertas: promedio histórico
    out["coolers_mean"] = g["num_coolers"].mean()
    out["doors_mean"]   = g["num_doors"].mean()

    out = out.reset_index().fillna(0)

    print(f"[4/4] Guardando {len(out):,} clientes -> {SALIDA.name}")
    out.to_csv(SALIDA, index=False)
    print("Listo. Columnas:", out.columns.tolist())


if __name__ == "__main__":
    main()
