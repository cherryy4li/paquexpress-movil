-- Creación de la base de datos
CREATE DATABASE IF NOT EXISTS paquexpress_db;
USE paquexpress_db;

-- Tabla: Usuario/Agente
CREATE TABLE Agentes (
    id_agente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE, -- Usado para el login
    password_hash VARCHAR(255) NOT NULL, -- Almacenará el hash de la contraseña (Bcrypt)
    session_token VARCHAR(255) NULL, -- Para manejar la sesión si no se usa JWT 
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla: Paquete
CREATE TABLE Paquetes (
    id_paquete INT AUTO_INCREMENT PRIMARY KEY,
    id_unico_paquete VARCHAR(50) NOT NULL UNIQUE, -- El ID único que ve el agente
    direccion_destino VARCHAR(255) NOT NULL,
    ciudad VARCHAR(100),
    estado VARCHAR(50),
    id_agente_asignado INT,
    estado_entrega ENUM('ASIGNADO', 'EN_RUTA', 'ENTREGADO', 'FALLIDO') DEFAULT 'ASIGNADO',
    FOREIGN KEY (id_agente_asignado) REFERENCES Agentes(id_agente)
);

-- Tabla: RegistroEntrega
CREATE TABLE RegistrosEntrega (
    id_registro INT AUTO_INCREMENT PRIMARY KEY,
    id_paquete INT NOT NULL UNIQUE, -- Cada paquete solo puede tener un registro final de entrega
    id_agente INT NOT NULL,
    latitud DECIMAL(10, 8) NOT NULL,
    longitud DECIMAL(11, 8) NOT NULL,
    url_foto_evidencia VARCHAR(255) NOT NULL, -- Ruta o URL donde se almacena la foto
    fecha_hora_entrega TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_paquete) REFERENCES Paquetes(id_paquete),
    FOREIGN KEY (id_agente) REFERENCES Agentes(id_agente)
);

-- Insertar un agente de prueba (La contraseña '123456' debe ser hasheada en la API)
-- Este insert es solo un ejemplo. La contraseña debe ser hasheada antes de insertarse.
INSERT INTO Agentes (nombre, email, password_hash) 
VALUES ('Juan Pérez', 'juan.perez@paquexpress.com', 'hash_de_123456_aqui'); 

-- Insertar paquetes de prueba
INSERT INTO Paquetes (id_unico_paquete, direccion_destino, id_agente_asignado) 
VALUES 
('PAQ-4521', 'Avenida Siempre Viva #742', 1),
('PAQ-8903', 'Calle Falsa #123, Colonia Centro', 1);