# api_fastapi/paquetes.py
from typing import List, Annotated
from fastapi import APIRouter, Depends, status, HTTPException
import mysql.connector

from .database import get_db
from .auth import get_current_user 
from .models import PaqueteAsignado, PaqueteEntrega

router = APIRouter()

# ----------------------------------------------------
# Endpoint 1: Obtener Paquetes Asignados
# (Cubre: Parte de "Estructura de base de datos funcional" y "Selección de paquete")
# ----------------------------------------------------
@router.get("/asignados", response_model=List[PaqueteAsignado])
def get_paquetes_asignados(
    current_user: Annotated[dict, Depends(get_current_user)],
    db: mysql.connector.connection.MySQLConnection = Depends(get_db)
):
    """
    Retorna la lista de paquetes pendientes para el agente autenticado.
    """
    agente_id = current_user["id_agente"]
    
    query = """
    SELECT 
        id_paquete, 
        id_unico_paquete, 
        direccion_destino, 
        estado_entrega 
    FROM Paquetes 
    WHERE id_agente_asignado = %s AND estado_entrega = 'ASIGNADO';
    """
    
    cursor = db.cursor(dictionary=True)
    cursor.execute(query, (agente_id,))
    paquetes = cursor.fetchall()
    cursor.close()
    
    return paquetes

# ----------------------------------------------------
# Endpoint 2: Registrar Entrega
# (Cubre: Selección de paquete, toma de foto, captura de GPS y almacenamiento básico - 2 Pts)
# ----------------------------------------------------
@router.post("/registrar_entrega", status_code=status.HTTP_201_CREATED)
def registrar_entrega(
    entrega: PaqueteEntrega,
    current_user: Annotated[dict, Depends(get_current_user)],
    db: mysql.connector.connection.MySQLConnection = Depends(get_db)
):
    """
    Registra la entrega final del paquete, actualizando el estado.
    """
    agente_id = current_user["id_agente"]
    
    try:
        cursor = db.cursor()
        
        # 1. Insertar en RegistrosEntrega (GPS y Foto)
        insert_registro = """
        INSERT INTO RegistrosEntrega 
        (id_paquete, id_agente, latitud, longitud, url_foto_evidencia)
        VALUES (%s, %s, %s, %s, %s);
        """
        cursor.execute(insert_registro, (
            entrega.id_paquete, 
            agente_id, 
            entrega.latitud, 
            entrega.longitud, 
            entrega.url_foto_evidencia
        ))
        
        # 2. Actualizar el estado en Paquetes
        update_paquete = """
        UPDATE Paquetes SET estado_entrega = 'ENTREGADO' 
        WHERE id_paquete = %s AND id_agente_asignado = %s;
        """
        cursor.execute(update_paquete, (entrega.id_paquete, agente_id))
        
        db.commit()
        cursor.close()
        
        return {"message": f"Entrega del paquete {entrega.id_paquete} registrada por {current_user['nombre']}."}

    except mysql.connector.IntegrityError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Error: El paquete ya ha sido entregado o el ID es incorrecto."
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error en el servidor: {str(e)}"
        )