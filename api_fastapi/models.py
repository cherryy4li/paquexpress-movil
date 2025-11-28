# api_fastapi/models.py
from pydantic import BaseModel

# --- Modelos de Autenticación ---

# Para recibir las credenciales del agente en el Login
class AgenteLogin(BaseModel):
    email: str
    password: str

# Para devolver el token al cliente (cumple con response_model)
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    id_agente: int
    nombre_agente: str

# --- Modelos de Paquetes y Entrega ---

# Estructura del paquete que se muestra en la lista
class PaqueteAsignado(BaseModel):
    id_paquete: int
    id_unico_paquete: str
    direccion_destino: str
    estado_entrega: str

# Estructura para registrar la entrega final
class PaqueteEntrega(BaseModel):
    id_paquete: int
    latitud: float
    longitud: float
    url_foto_evidencia: str # La URL o ruta donde se guardó la foto