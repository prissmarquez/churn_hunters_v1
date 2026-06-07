"""
Api.py   (PERSONA B)
-----------------------------------------------------------
API REST (FastAPI). Une TU parte con la de la Persona A:

  - scores.csv            <- lo entrega la PERSONA A (customer_id + probabilidad)
  - customer_features.csv <- lo generas TU con data_loader.py

Al arrancar las une por customer_id y sirve:
  GET /clientes        -> lista con score (JSON listo para Flutter)
  GET /clientes/{id}   -> detalle + explicación de riesgo
  GET /buscar          -> filtra por riesgo, territorio, subcanal, tamaño

DETECCION AUTOMATICA: como no sabes el formato exacto de la Persona A,
la API busca sola la columna de id y la de probabilidad entre varios
nombres posibles. Si no existe scores.csv todavia, usa un score
PROVISIONAL calculado de tus features para que puedas avanzar hoy.

Correr (desde la carpeta Api/):
  python -m uvicorn Api:app --reload --port 8000
Docs: http://localhost:8000/docs
-----------------------------------------------------------
"""
from pathlib import Path
from contextlib import asynccontextmanager
import pandas as pd
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

from Ia import explicar

DATA = Path(__file__).resolve().parent.parent / "data"

# nombres posibles para auto-detectar el archivo de la Persona A
ID_CAND   = ["customer_id", "id", "id_cliente", "cliente"]
PROB_CAND = ["probabilidad_churn", "churn_proba", "prob_churn", "probabilidad",
             "probability", "proba", "score_proba", "churn_probability", "p_churn"]
SCORE_CAND = ["score", "riesgo", "nivel", "risk_level", "nivel_riesgo"]

_DB: pd.DataFrame = None
_MODO = "—"   # "Persona A" o "PROVISIONAL"


def _nivel(p):
    return "alto" if p >= 0.60 else "medio" if p >= 0.30 else "bajo"


def _detectar(cols, candidatos):
    low = {c.lower(): c for c in cols}
    for c in candidatos:
        if c in low:
            return low[c]
    return None


def _cargar_scores():
    """Lee el scores.csv de la Persona A y normaliza columnas."""
    f = DATA / "scores.csv"
    if not f.exists():
        return None
    df = pd.read_csv(f)
    col_id = _detectar(df.columns, ID_CAND)
    col_p  = _detectar(df.columns, PROB_CAND)
    if not col_id or not col_p:
        raise RuntimeError(
            f"scores.csv no tiene columnas reconocibles. "
            f"Necesito un id ({ID_CAND}) y una probabilidad ({PROB_CAND}). "
            f"Encontré: {list(df.columns)}")
    out = df.rename(columns={col_id: "customer_id", col_p: "probabilidad_churn"})
    # si viene en escala 0-100, normalizar a 0-1
    if out["probabilidad_churn"].max() > 1.5:
        out["probabilidad_churn"] = out["probabilidad_churn"] / 100.0
    # nivel: usar el de A si lo trae, si no derivarlo
    col_s = _detectar(df.columns, SCORE_CAND)
    if col_s:
        out["riesgo"] = df[col_s].astype(str).str.lower()
    else:
        out["riesgo"] = out["probabilidad_churn"].apply(_nivel)
    keep = ["customer_id", "probabilidad_churn", "riesgo"]
    if "features_influyentes" in df.columns:
        out["features_influyentes"] = df["features_influyentes"]
        keep.append("features_influyentes")
    return out[keep]


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _DB, _MODO
    feats = pd.read_csv(DATA / "customer_features.csv")
    scores = _cargar_scores()

    if scores is not None:
        _DB = feats.merge(scores, on="customer_id", how="inner")
        _MODO = "Persona A (scores.csv)"
    else:
        # PROVISIONAL: score heuristico de tus propias features, para no bloquearte
        feats["probabilidad_churn"] = _provisional(feats)
        feats["riesgo"] = feats["probabilidad_churn"].apply(_nivel)
        _DB = feats
        _MODO = "PROVISIONAL (falta scores.csv de Persona A)"

    _DB = _DB.set_index("customer_id")
    print(f"[API] {len(_DB):,} clientes | fuente del score: {_MODO}")
    yield


def _provisional(df):
    """Heuristica simple SOLO para desarrollar sin la Persona A."""
    r3, r6 = df["trans_roll3"].clip(lower=0), df["trans_roll6"].clip(lower=1)
    caida = (1 - (r3 / r6)).clip(0, 1)
    inactivo = (df["trans_lag1"] == 0).astype(float)
    p = 0.6 * caida + 0.4 * inactivo
    return p.clip(0, 1).round(4)


app = FastAPI(title="Churn Hunters API (Persona B)", version="1.0", lifespan=lifespan)
# CORS abierto para que Flutter pueda consumir la API en desarrollo
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"],
                   allow_headers=["*"])


class ClienteResumen(BaseModel):
    customer_id: str
    probabilidad_churn: float
    riesgo: str
    territorio: Optional[str] = None
    subcanal: Optional[str] = None
    tamano: Optional[str] = None


def _s(x):
    """texto seguro: NaN/None -> None (evita que pydantic truene)."""
    if x is None:
        return None
    try:
        if x != x:   # NaN
            return None
    except TypeError:
        pass
    return str(x)


def _resumen(idx, row):
    return ClienteResumen(
        customer_id=str(idx),
        probabilidad_churn=round(float(row["probabilidad_churn"]), 4),
        riesgo=str(row["riesgo"]),
        territorio=_s(row.get("territory_d")),
        subcanal=_s(row.get("comercial_subchannel_d")),
        tamano=_s(row.get("rtm_customer_size_d")),
    )


@app.get("/clientes", response_model=list[ClienteResumen])
def listar(limit: int = Query(50, ge=1, le=2000), offset: int = Query(0, ge=0),
           orden: str = Query("riesgo", pattern="^(riesgo|alfabetico)$")):
    """Lista paginada de clientes con su score."""
    df = _DB.sort_values("probabilidad_churn", ascending=False) if orden == "riesgo" else _DB
    df = df.iloc[offset: offset + limit]
    return [_resumen(i, r) for i, r in df.iterrows()]


@app.get("/clientes/{customer_id}")
def detalle(customer_id: str):
    """Detalle de un cliente + explicación de por qué tiene ese riesgo."""
    if customer_id not in _DB.index:
        raise HTTPException(404, "Cliente no encontrado")
    row = _DB.loc[customer_id]
    expl = explicar(row.to_dict(), row["probabilidad_churn"], row["riesgo"])
    resp = {
        "customer_id": customer_id,
        "territorio": _s(row.get("territory_d")),
        "subcanal": _s(row.get("comercial_subchannel_d")),
        "tamano": _s(row.get("rtm_customer_size_d")),
        "features_clave": {
            "transacciones_ultimo_mes": round(float(row.get("trans_lag1", 0)), 1),
            "promedio_3m": round(float(row.get("trans_roll3", 0)), 1),
            "promedio_6m": round(float(row.get("trans_roll6", 0)), 1),
            "tendencia": round(float(row.get("trend", 0)), 1),
            "meses_activos_3m": float(row.get("meses_activos_3m", 0)),
            "coolers_promedio": round(float(row.get("coolers_mean", 0)), 1),
        },
        "explicacion": expl,
    }
    if "features_influyentes" in row:   # si la Persona A lo mandó
        resp["features_influyentes_modelo"] = row["features_influyentes"]
    return resp


@app.get("/buscar", response_model=list[ClienteResumen])
def buscar(riesgo_min: float = Query(0.0, ge=0, le=1),
           riesgo_max: float = Query(1.0, ge=0, le=1),
           nivel: Optional[str] = Query(None, pattern="^(alto|medio|bajo)$"),
           territorio: Optional[str] = None, subcanal: Optional[str] = None,
           tamano: Optional[str] = None, limit: int = Query(100, ge=1, le=2000)):
    """Filtra clientes por riesgo y atributos comerciales."""
    df = _DB
    m = (df["probabilidad_churn"] >= riesgo_min) & (df["probabilidad_churn"] <= riesgo_max)
    if nivel:      m &= df["riesgo"] == nivel
    if territorio: m &= df["territory_d"] == territorio
    if subcanal:   m &= df["comercial_subchannel_d"] == subcanal
    if tamano:     m &= df["rtm_customer_size_d"] == tamano
    df = df[m].sort_values("probabilidad_churn", ascending=False).head(limit)
    return [_resumen(i, r) for i, r in df.iterrows()]


@app.get("/")
def raiz():
    return {"api": "Churn Hunters (Persona B)", "fuente_score": _MODO,
            "clientes": 0 if _DB is None else len(_DB), "docs": "/docs"}
