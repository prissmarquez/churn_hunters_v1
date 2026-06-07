"""
Asistente.py   (PERSONA B)
-----------------------------------------------------------
Punto 5: IA CONVERSACIONAL (LLM = Google Gemini vía API).

A diferencia de Ia.py (reglas, explica UN cliente), este modulo
responde PREGUNTAS ABIERTAS de negocio sobre TODA la cartera:
  - "¿por qué estamos perdiendo clientes?"
  - "¿cuánto volumen está en riesgo este mes?"
  - "¿qué territorio debería priorizar el equipo comercial?"

IDEA CLAVE: el LLM NO conoce tus datos. Solo sabe lo que le metes
en el prompt. Por eso construimos un "contexto" = un resumen
estructurado calculado de _DB (agregados, segmentos, factores).
El LLM solo razona y redacta SOBRE ESE RESUMEN; nunca inventa cifras.

La API lo usa en POST /preguntar.

Requisitos:
  pip install google-genai
  variable de entorno GEMINI_API_KEY=...   (de aistudio.google.com)
-----------------------------------------------------------
"""
import os
import pandas as pd
from google import genai
from google.genai import types

# Modelo de la capa gratis, ideal para análisis + redacción.
MODELO = "gemini-2.5-flash"

# Si algún día tienen el valor promedio en pesos por caja, ponlo aquí
# y el contexto agregará el dinero en riesgo en MXN. Si se queda en None,
# el asistente habla en volumen (cajas / transacciones), sin inventar pesos.
VALOR_CAJA_MXN = None   # p.ej. 85.0

_cliente_llm = None


def _get_cliente():
    """Crea el cliente de Gemini una sola vez. Lee la key del entorno."""
    global _cliente_llm
    if _cliente_llm is None:
        key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
        if not key:
            raise RuntimeError(
                "Falta GEMINI_API_KEY. Defínela antes de arrancar la API:\n"
                "  PowerShell:  $env:GEMINI_API_KEY=\"...\"\n"
                "  CMD:         set GEMINI_API_KEY=...\n"
                "  Linux/Mac:   export GEMINI_API_KEY=...\n"
                "  (la sacas gratis en https://aistudio.google.com/apikey)")
        _cliente_llm = genai.Client(api_key=key)
    return _cliente_llm


# ---------------------------------------------------------------------------
# 1) CONSTRUCCIÓN DEL CONTEXTO  (se calcula UNA vez al arrancar la API)
# ---------------------------------------------------------------------------

def _top_segmento(db, col, etiqueta, n=5):
    """Top n valores de una columna entre los clientes de riesgo alto."""
    if col not in db.columns:
        return f"  ({etiqueta}: columna no disponible)"
    alto = db[db["riesgo"] == "alto"]
    if alto.empty:
        return f"  ({etiqueta}: sin clientes de riesgo alto)"
    vc = alto[col].fillna("(sin dato)").value_counts().head(n)
    lineas = [f"    - {idx}: {int(c):,} clientes en riesgo alto" for idx, c in vc.items()]
    return f"  Por {etiqueta} (riesgo alto):\n" + "\n".join(lineas)


def construir_contexto_global(db: pd.DataFrame) -> str:
    """
    Devuelve un bloque de texto con TODOS los números que el LLM puede usar.
    Se calcula una sola vez (es barato) y se inyecta en el system prompt.
    """
    total = len(db)
    nivel = db["riesgo"].astype(str)
    n_alto = int((nivel == "alto").sum())
    n_medio = int((nivel == "medio").sum())
    n_bajo = int((nivel == "bajo").sum())
    pct = lambda n: (n / total * 100) if total else 0

    # --- volumen en riesgo (usa cajas del último trimestre como proxy mensual)
    vol_txt = ""
    if "boxes_roll3" in db.columns:
        cajas_alto = float(db.loc[nivel == "alto", "boxes_roll3"].clip(lower=0).sum())
        cajas_medio = float(db.loc[nivel == "medio", "boxes_roll3"].clip(lower=0).sum())
        vol_txt = (f"- Volumen mensual aprox. en riesgo (cajas/mes, prom. 3m):\n"
                   f"    riesgo alto: {cajas_alto:,.0f} cajas | "
                   f"riesgo medio: {cajas_medio:,.0f} cajas\n")
        if VALOR_CAJA_MXN:
            vol_txt += (f"    valor estimado en riesgo alto: "
                        f"${cajas_alto * VALOR_CAJA_MXN:,.0f} MXN/mes "
                        f"(a ${VALOR_CAJA_MXN:.0f}/caja)\n")

    # --- frecuencia de factores de riesgo (mismas reglas que Ia.py, vectorizado)
    alto = db[nivel == "alto"]
    fact_txt = "- Sin clientes de riesgo alto para perfilar factores."
    if not alto.empty and "trans_lag1" in alto.columns:
        na = len(alto)
        inactivos = int((alto["trans_lag1"].fillna(0) == 0).sum())
        r3 = alto.get("trans_roll3", pd.Series(0, index=alto.index)).fillna(0)
        r6 = alto.get("trans_roll6", pd.Series(0, index=alto.index)).fillna(0)
        declive = int(((r6 > 0) & (r3 < r6 * 0.6)).sum())
        baja_frec = int((alto.get("meses_activos_3m", pd.Series(3, index=alto.index)).fillna(3) <= 1).sum())
        sin_cooler = int((alto.get("coolers_mean", pd.Series(1, index=alto.index)).fillna(0) == 0).sum())
        fact_txt = (
            "- Factores presentes en los clientes de riesgo ALTO:\n"
            f"    - No compraron el último mes: {inactivos:,} ({inactivos/na*100:.0f}%)\n"
            f"    - Caída fuerte vs. semestre previo: {declive:,} ({declive/na*100:.0f}%)\n"
            f"    - Compraron ≤1 de los últimos 3 meses: {baja_frec:,} ({baja_frec/na*100:.0f}%)\n"
            f"    - Sin coolers asignados: {sin_cooler:,} ({sin_cooler/na*100:.0f}%)")

    contexto = f"""DATOS REALES DE LA CARTERA (única fuente de cifras permitida):

- Cartera total analizada: {total:,} clientes.
- Distribución de riesgo de churn:
    riesgo alto:  {n_alto:,} ({pct(n_alto):.1f}%)
    riesgo medio: {n_medio:,} ({pct(n_medio):.1f}%)
    riesgo bajo:  {n_bajo:,} ({pct(n_bajo):.1f}%)
{vol_txt}{fact_txt}

Segmentación de los clientes de RIESGO ALTO:
{_top_segmento(db, "territory_d", "territorio")}
{_top_segmento(db, "rtm_customer_size_d", "tamaño")}
{_top_segmento(db, "comercial_subchannel_d", "subcanal")}

Definición de churn del reto: un cliente "churnea" si deja de comprar
(0 transacciones) en el mes objetivo. El score de riesgo se predice con
historia previa (lags y tendencias), nunca con el mes en curso."""
    return contexto


# ---------------------------------------------------------------------------
# 2) DETALLE DE UN CLIENTE  (opcional, reusa la explicación de reglas)
# ---------------------------------------------------------------------------

def _bloque_cliente(db, cliente_id):
    """Si la pregunta es sobre un cliente puntual, agrega sus números."""
    try:
        from Ia import explicar
    except ImportError:
        from .Ia import explicar  # por si se importa como paquete
    if cliente_id not in db.index:
        return f"\n\n(El cliente {cliente_id} no existe en la cartera.)"
    row = db.loc[cliente_id]
    expl = explicar(row.to_dict(), row["probabilidad_churn"], row["riesgo"])
    factores = "; ".join(f["descripcion"] for f in expl["factores"]) or "sin factores destacados"
    return (
        f"\n\nCLIENTE EN FOCO ({cliente_id}):\n"
        f"- Riesgo: {row['riesgo']} ({float(row['probabilidad_churn'])*100:.0f}%)\n"
        f"- Territorio: {row.get('territory_d')} | Tamaño: {row.get('rtm_customer_size_d')} "
        f"| Subcanal: {row.get('comercial_subchannel_d')}\n"
        f"- Transacciones último mes: {float(row.get('trans_lag1', 0)):.0f} | "
        f"prom 3m: {float(row.get('trans_roll3', 0)):.0f} | prom 6m: {float(row.get('trans_roll6', 0)):.0f}\n"
        f"- Factores: {factores}")


# ---------------------------------------------------------------------------
# 3) RESPUESTA DEL LLM
# ---------------------------------------------------------------------------

_SISTEMA = """Eres un analista comercial y financiero de Arca Continental (embotellador de Coca-Cola). Tu trabajo es ayudar al equipo comercial a entender y reducir el churn (clientes —tienditas tradicionales— que dejan de comprar).

Tienes un bloque "DATOS REALES DE LA CARTERA" con cifras agregadas calculadas del modelo de churn. Reglas estrictas:

1. SOLO usas las cifras que aparecen en los datos provistos. Está PROHIBIDO inventar números, porcentajes o montos que no estén ahí. Si te piden un dato que no está, dilo claramente y sugiere cómo obtenerlo.
2. Respondes en español, claro y directo, con enfoque de negocio (no técnico). Eres conciso: ve al grano.
3. Cuando des pronósticos o recomendaciones, fundaméntalas en los factores y segmentos de los datos (p.ej. "X% de los de riesgo alto no compró el último mes -> priorizar visita").
4. Si el usuario pide acciones, da recomendaciones priorizadas y accionables para el equipo de ventas.
5. Distingue correlación de causa: explica las SEÑALES de riesgo, sin afirmar causas que los datos no prueban.
6. No uses tablas ni markdown pesado salvo que ayude; prosa breve y, si acaso, listas cortas."""


def responder(pregunta: str, db: pd.DataFrame, contexto_global: str,
              historial: list | None = None, cliente_id: str | None = None,
              max_tokens: int = 1024) -> str:
    """
    pregunta        : texto del usuario.
    db              : el _DB de la API (indexado por customer_id).
    contexto_global : lo que devolvió construir_contexto_global() al arrancar.
    historial       : lista opcional [{"role","content"}, ...] para chat multiturno.
                      role "assistant" se mapea a "model" (formato Gemini).
    cliente_id      : opcional, para enfocar la respuesta en un cliente.
    """
    sistema = _SISTEMA + "\n\n" + contexto_global

    contenido = pregunta.strip()
    if cliente_id:
        contenido += _bloque_cliente(db, cliente_id)

    # Gemini usa roles "user"/"model" y estructura parts[].
    contents = []
    if historial:
        for m in historial:
            role = "model" if str(m.get("role", "")).lower() in ("assistant", "model") else "user"
            contents.append({"role": role, "parts": [{"text": str(m.get("content", ""))}]})
    contents.append({"role": "user", "parts": [{"text": contenido}]})

    resp = _get_cliente().models.generate_content(
        model=MODELO,
        contents=contents,
        config=types.GenerateContentConfig(
            system_instruction=sistema,
            max_output_tokens=max_tokens,
        ),
    )
    return (resp.text or "").strip()
