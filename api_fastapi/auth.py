# api_fastapi/auth.py
from datetime import datetime, timedelta, timezone
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
import bcrypt
import mysql.connector

from .database import get_db
from .models import AgenteLogin, Token


SECRET_KEY = "oGHTfCZyPY+5HukK17zxl1sQVpq2uPpwXoEc1c7KO6M=" 
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30 

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")
router = APIRouter()

# --- Funciones de Hash (Bcrypt) ---

def hash_password(password: str) -> str:
    """Hashea una contraseña usando Bcrypt."""
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    return hashed.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica una contraseña plana contra su hash."""
    return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))

# --- Funciones de Token (JWT) ---

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    """Crea un JWT."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(token: Annotated[str, Depends(oauth2_scheme)], db: mysql.connector.connection.MySQLConnection = Depends(get_db)):
    """Dependencia que verifica el token y obtiene el usuario autenticado."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudieron validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    # Buscar el agente en la BD
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT id_agente, nombre FROM Agentes WHERE id_agente = %s", (user_id,))
    user = cursor.fetchone()
    cursor.close()

    if user is None:
        raise credentials_exception
    
    return user

# --- Endpoint de Login ---
@router.post("/login", response_model=Token)
async def login_for_access_token(
    form_data: AgenteLogin, 
    db: mysql.connector.connection.MySQLConnection = Depends(get_db)
):
    """
    Endpoint de login. Valida credenciales y devuelve un JWT.
    (Cubre: Validación de sesión de usuario y autenticación básica - 2 Pts)
    """
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT id_agente, nombre, password_hash FROM Agentes WHERE email = %s", (form_data.email,))
    agente = cursor.fetchone()
    cursor.close()

    if not agente or not verify_password(form_data.password, agente["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales de acceso inválidas"
        )
    
    # Generar el Token JWT
    access_token = create_access_token(
        data={"sub": str(agente["id_agente"])}
    )

    return Token(
        access_token=access_token, 
        token_type="bearer",
        id_agente=agente["id_agente"],
        nombre_agente=agente["nombre"]
    )