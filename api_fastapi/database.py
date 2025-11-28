# api_fastapi/database.py
import mysql.connector
from mysql.connector import pooling
import os

# ⚠️ ADVERTENCIA: Reemplaza estos valores con tus credenciales de MySQL
DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"), 
    "user": os.environ.get("DB_USER", "root"), 
    "password": os.environ.get("DB_PASSWORD", "040319"), 
    "database": "paquexpress_db" 
}

# Usaremos un Pool de Conexiones
try:
    db_pool = mysql.connector.pooling.MySQLConnectionPool(
        pool_name="paquexpress_pool",
        pool_size=5, 
        **DB_CONFIG
    )
    print("Pool de conexiones a MySQL creado exitosamente.")

except mysql.connector.Error as err:
    print(f"Error al conectar a MySQL: {err}")
    # En un entorno de producción, aquí deberías terminar la aplicación.
    db_pool = None

# Función generadora para obtener la conexión
def get_db():
    """Obtiene una conexión del pool y la libera al finalizar."""
    if db_pool is None:
        raise Exception("No se pudo establecer la conexión a la base de datos.")
        
    conn = None
    try:
        conn = db_pool.get_connection()
        yield conn 
    except Exception as e:
        # Aquí puedes manejar errores específicos de MySQL
        print(f"Error en la transacción de base de datos: {e}")
        raise 
    finally:
        if conn:
            conn.close()