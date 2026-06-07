"""
Ia.py   (PERSONA B)
-----------------------------------------------------------
Punto 4: IA explicativa con reglas + plantillas.

Recibe las features de un cliente y arma una justificacion legible
de por que tiene ese riesgo. 100% interpretable, no caja negra.
La API la usa en /clientes/{id}.
-----------------------------------------------------------
"""
from dataclasses import dataclass


@dataclass
class Factor:
    descripcion: str
    severidad: str   # "alta" | "media" | "baja"


def _f(x, d=0.0):
    try:
        v = float(x)
        return d if v != v else v
    except (TypeError, ValueError):
        return d


def _r_actividad(f):
    t = _f(f.get("trans_lag1"))
    if t == 0:
        return Factor("No registró transacciones en su último mes.", "alta")
    if t <= 3:
        return Factor(f"Apenas {int(t)} transacción(es) en su último mes.", "alta")
    return None


def _r_declive(f):
    r3, r6 = _f(f.get("trans_roll3")), _f(f.get("trans_roll6"))
    if r6 > 0 and r3 < r6 * 0.6:
        return Factor(f"Sus compras cayeron {(1 - r3/r6)*100:.0f}% vs. el semestre previo.", "alta")
    if _f(f.get("trend")) < -2:
        return Factor("Tendencia de compra a la baja en los últimos meses.", "media")
    return None


def _r_frecuencia(f):
    m = _f(f.get("meses_activos_3m"), 3)
    if m <= 1:
        return Factor(f"Compró solo {int(m)} de los últimos 3 meses.", "media")
    return None


def _r_coolers(f):
    c = _f(f.get("coolers_mean"))
    if c == 0:
        return Factor("No tiene coolers asignados (menor vínculo comercial).", "media")
    if c < 1:
        return Factor("Presencia mínima de coolers en el punto de venta.", "baja")
    return None


def _r_tamano(f):
    if str(f.get("rtm_customer_size_d", "")).lower() in ("mini", "pequeño", "pequeno"):
        return Factor("Cliente pequeño, históricamente más volátil.", "baja")
    return None


REGLAS = [_r_actividad, _r_declive, _r_frecuencia, _r_coolers, _r_tamano]

_PLANTILLA = {
    "alto":  "Riesgo ALTO de churn ({p:.0f}%). {m} Acción: visita prioritaria esta semana.",
    "medio": "Riesgo MEDIO ({p:.0f}%). {m} Acción: dar seguimiento al próximo pedido.",
    "bajo":  "Riesgo BAJO ({p:.0f}%). Comportamiento estable, sin señales de alerta.",
}


def explicar(features: dict, proba: float, nivel: str) -> dict:
    fs = [r(features) for r in REGLAS]
    fs = [x for x in fs if x]
    fs.sort(key=lambda x: {"alta": 0, "media": 1, "baja": 2}[x.severidad])
    motivos = ("Motivos: " + " ".join(x.descripcion for x in fs)) if fs else ""
    narrativa = _PLANTILLA[nivel].format(p=proba * 100, m=motivos).strip()
    return {
        "nivel": nivel,
        "probabilidad": round(float(proba), 4),
        "factores": [{"descripcion": x.descripcion, "severidad": x.severidad} for x in fs],
        "narrativa": narrativa,
    }
