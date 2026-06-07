# churn_v1
## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# churn_hunters_v1

## Churn Hunters

Sistema de predicción y análisis de churn de clientes para Arca Continental. Predice qué tienditas están en riesgo de dejar de comprar, explica por qué, y permite consultar la cartera con un asistente de IA.

# El problema / qué resuelve — el contexto: qué problema atacas y cómo. 

Arca Continental pierde clientes (tiendas tradicionales) cada mes sin saber con anticipación cuáles ni por qué. Para cuando se detecta la caída en ventas, el cliente ya se fue. Este proyecto ataca ese problema en tres frentes: predice qué clientes tienen alto riesgo de churn el próximo mes usando su historial de compras, explica ese riesgo en lenguaje de negocio (no como caja negra), y ofrece un asistente de IA que responde preguntas abiertas sobre la cartera para que el equipo comercial priorice a quién visitar y qué acciones tomar.

# Funcionalidades — lista de lo que hace la app (dashboard, predicción, chat con IA, reporte).

Dashboard de cartera: muestra el porcentaje de clientes en riesgo (alto, medio, bajo) y el volumen de cajas mensuales en riesgo.

Predicción de churn: cada cliente recibe una probabilidad de abandono y un nivel de riesgo calculado por el modelo de Machine Learning.

Búsqueda y filtros: lista de clientes filtrable por nivel de riesgo, territorio, subcanal y tamaño, además de búsqueda por ID.

Detalle de cliente: ficha individual con sus features clave (actividad reciente, tendencia, coolers) y una explicación automática de por qué está en riesgo.

Chat con IA (general): un asistente conversacional que responde preguntas abiertas sobre toda la cartera, por ejemplo por qué se pierden clientes o qué territorio priorizar, usando únicamente las cifras reales del modelo.

Chat con IA (por cliente): desde el detalle de un cliente se puede preguntar específicamente sobre ese cliente.

Reporte: vista de reporte de la cartera.

# Tecnologías / stack — qué usaste (Python, XGBoost, FastAPI, Gemini, Flutter).
# Instalación y cómo correrlo — los pasos para levantarlo.

Machine Learning: Python, pandas, scikit-learn / XGBoost para el modelo de churn.

Backend / API: Python con FastAPI y Uvicorn.

IA conversacional: Google Gemini (modelo gemini-2.5-flash) vía la librería google-genai.

Frontend: Flutter (Dart), con el paquete http para consumir la API.

## Importante:
En caso de no poder usar la API proporcionada, dirigirse a: https://aistudio.google.com/api-keys?project=gen-lang-client-0569289401 En el lado superior derecho en “Crear clave de API”  “Crear Clave”  “Copiar clave”  Remplazar en: 

Si es Mac: 
# 0. clonar el repo y entrar
git clone <URL-del-repo>
cd <nombre-del-repo>/lib/backend/Api

# 1. crear el entorno virtual
python3 -m venv venv

# 2. activarlo  (debe aparecer (venv) al inicio)
source venv/bin/activate

# 3. instalar dependencias
pip install fastapi uvicorn pandas google-genai

# 4. poner SU propia key de Gemini (gratis en aistudio.google.com/apikey)
export GEMINI_API_KEY="SU_API_KEY" 

# 5. generar features (una vez) -- requiere los datos colocados (ver abajo)
python3 build_features.py

# 6. levantar la API
python3 -m uvicorn Api:app --reload --port 8000


Si es windows
# 0. clonar y entrar
git clone <URL-del-repo>
cd <nombre-del-repo>\lib\backend\Api
# 1. crear el venv
python -m venv venv

# 2. activarlo
.\venv\Scripts\Activate.ps1

# 3. instalar
pip install fastapi uvicorn pandas google-genai

# 4. su propia key
"$env:GEMINI_API_KEY="SU_API_KEY"

# 5. generar features (una vez)
python build_features.py

# 6. levantar
python -m uvicorn Api:app --reload --port 8000
Clave API: 
Host para la API (Json): http://localhost:8000/docs 

# Para correr flutter:
En una terminal aparte:
flutter pub get
flutter run
Archivos de datos necesarios
Algunos archivos no estan en el repositorio por su tamaño o por seguridad y deben aplicarse localmente antes de correr el backend:

data/processed/churn_scores_final.csv (predicciones del modelo, lo lee la API)
data/processed/X_all_clients_prepared.csv (panel mensual, lo lee build_features.py)
data/Clientes.csv, data/Coolers.csv, data/sales_churn_train.csv, data/sales_churn_test.csv (datos crudos del reto)

# Uso — cómo se navega/usa una vez corriendo.

Una vez corriendo la app, la pantalla principal es el dashboard, que muestra el porcentaje de la cartera en riesgo y el volumen de cajas en riesgo. Desde ahí se puede:
Cambiar el nivel de riesgo (Alto, Medio, Bajo) con el filtro para ver los clientes de cada grupo.
Buscar un cliente por su ID en la barra de búsqueda.
Tocar un cliente de la lista para abrir su detalle, donde se ve su información, su riesgo y la explicación de por que está en riesgo, además de un chat para preguntar sobre ese cliente.
Tocar el botón Asistente IA para abrir el chat general y preguntar sobre toda la cartera (por ejemplo: por que se pierden clientes, que territorio priorizar, cuanto volumen está en riesgo). Hay preguntas sugeridas para empezar.
Tocar el botón Reporte para ver el reporte de la cartera.


https://drive.google.com/drive/folders/1qVVMj7xBwTfCgDCxuil2omj53c0aPR6K?usp=sharing