"""Modelos ORM de SaludMayor Blog. La estructura se administra mediante SQL."""
from sqlalchemy import (Boolean, String, CHAR, DateTime, Text, ForeignKey,
                        CheckConstraint, UniqueConstraint, Index, text, FetchedValue)
from sqlalchemy.dialects.mysql import INTEGER, BIGINT, TINYINT, ENUM, MEDIUMBLOB, LONGTEXT
from sqlalchemy.orm import mapped_column, relationship
from database import Base


class Usuario(Base):
    __tablename__ = "usuario"
    __table_args__ = (
        CheckConstraint("(foto_perfil IS NULL AND tipo_imagen IS NULL) OR (foto_perfil IS NOT NULL AND tipo_imagen IS NOT NULL AND tipo_imagen IN ('image/jpeg','image/png','image/webp') AND OCTET_LENGTH(foto_perfil) BETWEEN 1 AND 2097152)", name='ck_usuario_imagen'),
        {"mysql_engine": "InnoDB"},
    )

    id_usuario = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    nombre = mapped_column(String(100), nullable=False)
    apellido_paterno = mapped_column(String(60), nullable=False)
    apellido_materno = mapped_column(String(60), nullable=True)
    correo = mapped_column(String(150), nullable=False, unique=True)
    contrasena = mapped_column(String(255), nullable=False, deferred=True)
    recuperacion_hash = mapped_column(String(255), nullable=True, deferred=True)
    rol = mapped_column(ENUM('administrador','usuario'), nullable=False, server_default=text("'usuario'"))
    estado = mapped_column(Boolean, nullable=False, server_default=text('TRUE'))
    fecha_registro = mapped_column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP'))
    foto_perfil = mapped_column(MEDIUMBLOB, nullable=True, deferred=True)
    tipo_imagen = mapped_column(String(50), nullable=True)

    publicaciones = relationship('Blog', back_populates='autor', passive_deletes="all")
    comentarios = relationship('Comentario', back_populates='usuario', passive_deletes="all")
    valoraciones = relationship('Valoracion', back_populates='usuario', passive_deletes="all")
    reacciones = relationship('Reaccion', back_populates='usuario', passive_deletes="all")
    mensajes_enviados = relationship('Mensaje', back_populates='emisor', foreign_keys='Mensaje.id_emisor', passive_deletes="all")
    mensajes_recibidos = relationship('Mensaje', back_populates='receptor', foreign_keys='Mensaje.id_receptor', passive_deletes="all")
    configuraciones = relationship('Configuracion', back_populates='usuario', passive_deletes="all")
    sesiones = relationship('Sesion', back_populates='usuario', passive_deletes="all")

class Categoria(Base):
    __tablename__ = "categorias"
    __table_args__ = (
        {"mysql_engine": "InnoDB"},
    )

    id_categoria = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    nombre = mapped_column(String(80), nullable=False, unique=True)
    descripcion = mapped_column(String(255), nullable=True)
    estado = mapped_column(Boolean, nullable=False, server_default=text('TRUE'))

    publicaciones = relationship('Blog', back_populates='categoria', passive_deletes="all")

class Blog(Base):
    __tablename__ = "blog"
    __table_args__ = (
        CheckConstraint("(imagen IS NULL AND tipo_imagen IS NULL) OR (imagen IS NOT NULL AND tipo_imagen IS NOT NULL AND tipo_imagen IN ('image/jpeg','image/png','image/webp') AND OCTET_LENGTH(imagen) BETWEEN 1 AND 5242880)", name='ck_blog_imagen'),
        Index('idx_blog_fecha', 'fecha_publicacion'),
        {"mysql_engine": "InnoDB"},
    )

    id_blog = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    id_usuario = mapped_column(INTEGER(unsigned=True), ForeignKey("usuario.id_usuario", name="fk_blog_usuario", ondelete="RESTRICT"), nullable=False)
    id_categoria = mapped_column(INTEGER(unsigned=True), ForeignKey("categorias.id_categoria", name="fk_blog_categoria", ondelete="RESTRICT"), nullable=False)
    titulo = mapped_column(String(150), nullable=False)
    descripcion = mapped_column(String(500), nullable=False)
    contenido = mapped_column(LONGTEXT, nullable=False)
    imagen = mapped_column(MEDIUMBLOB, nullable=True, deferred=True)
    tipo_imagen = mapped_column(String(50), nullable=True)
    fecha_publicacion = mapped_column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP'))
    fecha_actualizacion = mapped_column(DateTime, nullable=True, server_default=text("NULL ON UPDATE CURRENT_TIMESTAMP"), server_onupdate=FetchedValue())

    autor = relationship('Usuario', back_populates='publicaciones')
    categoria = relationship('Categoria', back_populates='publicaciones')
    comentarios = relationship('Comentario', back_populates='blog', cascade="all, delete", passive_deletes=True)
    valoraciones = relationship('Valoracion', back_populates='blog', cascade="all, delete", passive_deletes=True)

class Comentario(Base):
    __tablename__ = "comentarios"
    __table_args__ = (
        CheckConstraint('CHAR_LENGTH(TRIM(comentario)) > 0', name='ck_com_texto'),
        Index('idx_com_blog_fecha', 'id_blog', 'fecha_comentario'),
        {"mysql_engine": "InnoDB"},
    )

    id_comentario = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    id_usuario = mapped_column(INTEGER(unsigned=True), ForeignKey("usuario.id_usuario", name="fk_com_usuario", ondelete="RESTRICT"), nullable=False)
    id_blog = mapped_column(INTEGER(unsigned=True), ForeignKey("blog.id_blog", name="fk_com_blog", ondelete="CASCADE"), nullable=False)
    comentario = mapped_column(Text, nullable=False)
    fecha_comentario = mapped_column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP'))
    estado = mapped_column(Boolean, nullable=False, server_default=text('TRUE'))

    usuario = relationship('Usuario', back_populates='comentarios')
    blog = relationship('Blog', back_populates='comentarios')
    reacciones = relationship('Reaccion', back_populates='comentario', cascade="all, delete", passive_deletes=True)

class Valoracion(Base):
    __tablename__ = "valoraciones"
    __table_args__ = (
        CheckConstraint('puntuacion BETWEEN 1 AND 5', name='ck_val_puntos'),
        UniqueConstraint('id_usuario', 'id_blog', name='uq_val_usuario_blog'),
        {"mysql_engine": "InnoDB"},
    )

    id_valoracion = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    id_usuario = mapped_column(INTEGER(unsigned=True), ForeignKey("usuario.id_usuario", name="fk_val_usuario", ondelete="RESTRICT"), nullable=False)
    id_blog = mapped_column(INTEGER(unsigned=True), ForeignKey("blog.id_blog", name="fk_val_blog", ondelete="CASCADE"), nullable=False)
    puntuacion = mapped_column(TINYINT(unsigned=True), nullable=False)
    fecha_valoracion = mapped_column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'), server_onupdate=FetchedValue())

    usuario = relationship('Usuario', back_populates='valoraciones')
    blog = relationship('Blog', back_populates='valoraciones')

class TipoReaccion(Base):
    __tablename__ = "tipo_reaccion"
    __table_args__ = (
        {"mysql_engine": "InnoDB"},
    )

    id_tipo_reaccion = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    nombre = mapped_column(String(50), nullable=False, unique=True)
    emoji = mapped_column(String(30), nullable=False)
    estado = mapped_column(Boolean, nullable=False, server_default=text('TRUE'))

    reacciones = relationship('Reaccion', back_populates='tipo_reaccion', passive_deletes="all")

class Reaccion(Base):
    __tablename__ = "reacciones"
    __table_args__ = (
        UniqueConstraint('id_usuario', 'id_comentario', name='uq_reac_usuario_com'),
        {"mysql_engine": "InnoDB"},
    )

    id_reaccion = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    id_usuario = mapped_column(INTEGER(unsigned=True), ForeignKey("usuario.id_usuario", name="fk_reac_usuario", ondelete="RESTRICT"), nullable=False)
    id_comentario = mapped_column(INTEGER(unsigned=True), ForeignKey("comentarios.id_comentario", name="fk_reac_com", ondelete="CASCADE"), nullable=False)
    id_tipo_reaccion = mapped_column(INTEGER(unsigned=True), ForeignKey("tipo_reaccion.id_tipo_reaccion", name="fk_reac_tipo", ondelete="RESTRICT"), nullable=False)
    fecha_reaccion = mapped_column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'), server_onupdate=FetchedValue())

    usuario = relationship('Usuario', back_populates='reacciones')
    comentario = relationship('Comentario', back_populates='reacciones')
    tipo_reaccion = relationship('TipoReaccion', back_populates='reacciones')

class Mensaje(Base):
    __tablename__ = "mensajes"
    __table_args__ = (
        CheckConstraint('CHAR_LENGTH(TRIM(mensaje)) > 0', name='ck_msg_texto'),
        CheckConstraint('(leido = 0 AND fecha_lectura IS NULL) OR (leido = 1 AND fecha_lectura IS NOT NULL AND fecha_lectura >= fecha_envio)', name='ck_msg_lectura'),
        Index('idx_msg_conversacion', 'id_emisor', 'id_receptor', 'fecha_envio'),
        Index('idx_msg_recibidos', 'id_receptor', 'leido', 'fecha_envio'),
        {"mysql_engine": "InnoDB"},
    )

    id_mensaje = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    id_emisor = mapped_column(INTEGER(unsigned=True), ForeignKey("usuario.id_usuario", name="fk_msg_emisor", ondelete="RESTRICT"), nullable=False)
    id_receptor = mapped_column(INTEGER(unsigned=True), ForeignKey("usuario.id_usuario", name="fk_msg_receptor", ondelete="RESTRICT"), nullable=False)
    mensaje = mapped_column(Text, nullable=False)
    fecha_envio = mapped_column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP'))
    leido = mapped_column(Boolean, nullable=False, server_default=text('FALSE'))
    fecha_lectura = mapped_column(DateTime, nullable=True)

    emisor = relationship('Usuario', back_populates='mensajes_enviados', foreign_keys='Mensaje.id_emisor')
    receptor = relationship('Usuario', back_populates='mensajes_recibidos', foreign_keys='Mensaje.id_receptor')

class Configuracion(Base):
    __tablename__ = "configuracion"
    __table_args__ = (
        CheckConstraint('id_configuracion = 1', name='ck_conf_unica'),
        CheckConstraint("(logotipo IS NULL AND tipo_imagen IS NULL) OR (logotipo IS NOT NULL AND tipo_imagen IS NOT NULL AND tipo_imagen IN ('image/jpeg','image/png','image/webp') AND OCTET_LENGTH(logotipo) BETWEEN 1 AND 2097152)", name='ck_conf_imagen'),
        {"mysql_engine": "InnoDB"},
    )

    id_configuracion = mapped_column(INTEGER(unsigned=True), primary_key=True, autoincrement=False)
    nombre_app = mapped_column(String(100), nullable=False)
    logotipo = mapped_column(MEDIUMBLOB, nullable=True, deferred=True)
    tipo_imagen = mapped_column(String(50), nullable=True)
    fecha_actualizacion = mapped_column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'), server_onupdate=FetchedValue())
    id_usuario = mapped_column(INTEGER(unsigned=True), ForeignKey("usuario.id_usuario", name="fk_conf_usuario", ondelete="RESTRICT"), nullable=True)

    usuario = relationship('Usuario', back_populates='configuraciones')

class Sesion(Base):
    __tablename__ = "sesiones"
    __table_args__ = (
        CheckConstraint('fecha_expiracion > fecha_inicio', name='ck_sesion_exp'),
        CheckConstraint('(revocada = 0 AND fecha_cierre IS NULL) OR (revocada = 1 AND fecha_cierre IS NOT NULL AND fecha_cierre >= fecha_inicio)', name='ck_sesion_cierre'),
        Index('idx_sesion_vigencia', 'id_usuario', 'revocada', 'fecha_expiracion'),
        {"mysql_engine": "InnoDB"},
    )

    id_sesion = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    id_usuario = mapped_column(INTEGER(unsigned=True), ForeignKey("usuario.id_usuario", name="fk_sesion_usuario", ondelete="RESTRICT"), nullable=False)
    identificador_token = mapped_column(CHAR(36), nullable=False, unique=True)
    fecha_inicio = mapped_column(DateTime, nullable=False, server_default=text('CURRENT_TIMESTAMP'))
    fecha_expiracion = mapped_column(DateTime, nullable=False)
    fecha_cierre = mapped_column(DateTime, nullable=True)
    revocada = mapped_column(Boolean, nullable=False, server_default=text('FALSE'))

    usuario = relationship('Usuario', back_populates='sesiones')