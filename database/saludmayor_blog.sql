-- SaludMayor Blog | Fase 1.3 | MySQL 8.0
-- Estructura inicial. Ejecutar sobre una base nueva.
CREATE DATABASE saludmayor_blog
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE saludmayor_blog;

CREATE TABLE usuario (
 id_usuario INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(100) NOT NULL,
 apellido_paterno VARCHAR(60) NOT NULL,
 apellido_materno VARCHAR(60),
 correo VARCHAR(150) NOT NULL UNIQUE,
 contrasena VARCHAR(255) NOT NULL,
 recuperacion_hash VARCHAR(255) NULL,
 rol ENUM('administrador','usuario') NOT NULL DEFAULT 'usuario',
 estado BOOLEAN NOT NULL DEFAULT TRUE,
 fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 foto_perfil MEDIUMBLOB,
 tipo_imagen VARCHAR(50),
 CONSTRAINT ck_usuario_imagen CHECK ((foto_perfil IS NULL AND tipo_imagen IS NULL) OR (foto_perfil IS NOT NULL AND tipo_imagen IS NOT NULL AND tipo_imagen IN ('image/jpeg','image/png','image/webp') AND OCTET_LENGTH(foto_perfil) BETWEEN 1 AND 2097152))
) ENGINE=InnoDB;

CREATE TABLE categorias (
 id_categoria INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(80) NOT NULL UNIQUE,
 descripcion VARCHAR(255),
 estado BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE blog (
 id_blog INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_usuario INT UNSIGNED NOT NULL,
 id_categoria INT UNSIGNED NOT NULL,
 titulo VARCHAR(150) NOT NULL,
 descripcion VARCHAR(500) NOT NULL,
 contenido LONGTEXT NOT NULL,
 imagen MEDIUMBLOB,
 tipo_imagen VARCHAR(50),
 fecha_publicacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_actualizacion DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_blog_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
 CONSTRAINT fk_blog_categoria FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria) ON DELETE RESTRICT,
 CONSTRAINT ck_blog_imagen CHECK ((imagen IS NULL AND tipo_imagen IS NULL) OR (imagen IS NOT NULL AND tipo_imagen IS NOT NULL AND tipo_imagen IN ('image/jpeg','image/png','image/webp') AND OCTET_LENGTH(imagen) BETWEEN 1 AND 5242880)),
 INDEX idx_blog_fecha (fecha_publicacion)
) ENGINE=InnoDB;

CREATE TABLE comentarios (
 id_comentario INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_usuario INT UNSIGNED NOT NULL,
 id_blog INT UNSIGNED NOT NULL,
 comentario TEXT NOT NULL,
 fecha_comentario DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 estado BOOLEAN NOT NULL DEFAULT TRUE,
 CONSTRAINT fk_com_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
 CONSTRAINT fk_com_blog FOREIGN KEY (id_blog) REFERENCES blog(id_blog) ON DELETE CASCADE,
 CONSTRAINT ck_com_texto CHECK (CHAR_LENGTH(TRIM(comentario)) > 0),
 INDEX idx_com_blog_fecha (id_blog, fecha_comentario)
) ENGINE=InnoDB;

CREATE TABLE valoraciones (
 id_valoracion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_usuario INT UNSIGNED NOT NULL,
 id_blog INT UNSIGNED NOT NULL,
 puntuacion TINYINT UNSIGNED NOT NULL,
 fecha_valoracion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_val_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
 CONSTRAINT fk_val_blog FOREIGN KEY (id_blog) REFERENCES blog(id_blog) ON DELETE CASCADE,
 CONSTRAINT ck_val_puntos CHECK (puntuacion BETWEEN 1 AND 5),
 CONSTRAINT uq_val_usuario_blog UNIQUE (id_usuario,id_blog)
) ENGINE=InnoDB;

CREATE TABLE tipo_reaccion (
 id_tipo_reaccion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 nombre VARCHAR(50) NOT NULL UNIQUE,
 emoji VARCHAR(30) NOT NULL,
 estado BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE reacciones (
 id_reaccion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_usuario INT UNSIGNED NOT NULL,
 id_comentario INT UNSIGNED NOT NULL,
 id_tipo_reaccion INT UNSIGNED NOT NULL,
 fecha_reaccion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 CONSTRAINT fk_reac_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
 CONSTRAINT fk_reac_com FOREIGN KEY (id_comentario) REFERENCES comentarios(id_comentario) ON DELETE CASCADE,
 CONSTRAINT fk_reac_tipo FOREIGN KEY (id_tipo_reaccion) REFERENCES tipo_reaccion(id_tipo_reaccion) ON DELETE RESTRICT,
 CONSTRAINT uq_reac_usuario_com UNIQUE (id_usuario,id_comentario)
) ENGINE=InnoDB;

CREATE TABLE mensajes (
 id_mensaje INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_emisor INT UNSIGNED NOT NULL,
 id_receptor INT UNSIGNED NOT NULL,
 mensaje TEXT NOT NULL,
 fecha_envio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 leido BOOLEAN NOT NULL DEFAULT FALSE,
 fecha_lectura DATETIME,
 CONSTRAINT fk_msg_emisor FOREIGN KEY (id_emisor) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
 CONSTRAINT fk_msg_receptor FOREIGN KEY (id_receptor) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
 CONSTRAINT ck_msg_texto CHECK (CHAR_LENGTH(TRIM(mensaje)) > 0),
 CONSTRAINT ck_msg_lectura CHECK ((leido = 0 AND fecha_lectura IS NULL) OR (leido = 1 AND fecha_lectura IS NOT NULL AND fecha_lectura >= fecha_envio)),
 INDEX idx_msg_conversacion (id_emisor,id_receptor,fecha_envio),
 INDEX idx_msg_recibidos (id_receptor,leido,fecha_envio)
) ENGINE=InnoDB;

CREATE TABLE configuracion (
 id_configuracion INT UNSIGNED PRIMARY KEY,
 nombre_app VARCHAR(100) NOT NULL,
 logotipo MEDIUMBLOB,
 tipo_imagen VARCHAR(50),
 fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 id_usuario INT UNSIGNED,
 CONSTRAINT fk_conf_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
 CONSTRAINT ck_conf_unica CHECK (id_configuracion = 1),
 CONSTRAINT ck_conf_imagen CHECK ((logotipo IS NULL AND tipo_imagen IS NULL) OR (logotipo IS NOT NULL AND tipo_imagen IS NOT NULL AND tipo_imagen IN ('image/jpeg','image/png','image/webp') AND OCTET_LENGTH(logotipo) BETWEEN 1 AND 2097152))
) ENGINE=InnoDB;

CREATE TABLE sesiones (
 id_sesion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 id_usuario INT UNSIGNED NOT NULL,
 identificador_token CHAR(36) NOT NULL UNIQUE,
 fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 fecha_expiracion DATETIME NOT NULL,
 fecha_cierre DATETIME,
 revocada BOOLEAN NOT NULL DEFAULT FALSE,
 CONSTRAINT fk_sesion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
 CONSTRAINT ck_sesion_exp CHECK (fecha_expiracion > fecha_inicio),
 CONSTRAINT ck_sesion_cierre CHECK ((revocada = 0 AND fecha_cierre IS NULL) OR (revocada = 1 AND fecha_cierre IS NOT NULL AND fecha_cierre >= fecha_inicio)),
 INDEX idx_sesion_vigencia (id_usuario,revocada,fecha_expiracion)
) ENGINE=InnoDB;


SHOW TABLES;