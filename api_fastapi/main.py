# api_fastapi/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from . import auth  # Importamos el módulo de autenticación
from . import paquetes # Importamos el módulo de paquetes

# --- Configuración de la API ---
app = FastAPI(
    title="Paquexpress API",
    version="1.0.0"
)

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    # Permite todos los orígenes por simplicidad en desarrollo
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Inclusión de Routers ---
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Autenticación"])
app.include_router(paquetes.router, prefix="/api/v1/paquetes", tags=["Paquetes"])

# Endpoint de Prueba
@app.get("/api/v1/status")
def get_status():
    return {"status": "API corriendo", "message": "Conectado a Paquexpress"}