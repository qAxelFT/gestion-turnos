CREATE DATABASE IF NOT EXISTS gestor_turnos
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gestor_turnos;

CREATE TABLE especialidades (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE medicos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  especialidad_id INT NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  FOREIGN KEY (especialidad_id) REFERENCES especialidades(id)
) ENGINE=InnoDB;

CREATE TABLE pacientes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(120) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  telefono VARCHAR(20)
) ENGINE=InnoDB;

CREATE TABLE slots (
  id INT AUTO_INCREMENT PRIMARY KEY,
  medico_id INT NOT NULL,
  inicio DATETIME NOT NULL,
  fin DATETIME NOT NULL,
  estado ENUM('libre','reservado') NOT NULL DEFAULT 'libre',
  UNIQUE KEY uq_medico_inicio (medico_id, inicio),
  KEY idx_busqueda (medico_id, estado, inicio),
  CONSTRAINT chk_rango CHECK (fin > inicio),
  FOREIGN KEY (medico_id) REFERENCES medicos(id)
) ENGINE=InnoDB;

CREATE TABLE citas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  slot_id INT NOT NULL,
  paciente_id INT NOT NULL,
  estado ENUM('activa','cancelada') NOT NULL DEFAULT 'activa',
  creada_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  cancelada_en DATETIME NULL,
  slot_activo INT AS (IF(estado='activa', slot_id, NULL)) PERSISTENT,
  UNIQUE KEY uq_slot_activo (slot_activo),
  KEY idx_paciente (paciente_id, estado),
  FOREIGN KEY (slot_id) REFERENCES slots(id),
  FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
) ENGINE=InnoDB;
