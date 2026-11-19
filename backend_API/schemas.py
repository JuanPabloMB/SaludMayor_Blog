"""Contratos de entrada y salida de la API REST de SaludMayor Blog."""
from datetime import datetime
from typing import Annotated, Literal

from pydantic import (BaseModel, ConfigDict, EmailStr, Field, SecretStr,
                      StringConstraints, TypeAdapter, field_validator, model_validator)

Id = Annotated[int, Field(strict=True, ge=1, le=4294967295)]
Puntuacion = Annotated[int, Field(strict=True, ge=1, le=5)]
Nombre = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=100)]
Apellido = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=60)]
Correo = Annotated[EmailStr, Field(max_length=150)]
Titulo = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=150)]
Descripcion = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=500)]
Contenido = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=50000)]
TextoCorto = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=4000)]
Rol = Literal['administrador', 'usuario']
MimeImagen = Literal['image/jpeg', 'image/png', 'image/webp']


class Entrada(BaseModel):
    """Rechaza campos no autorizados, incluso si el cliente los inventa."""
    model_config = ConfigDict(extra='forbid', hide_input_in_errors=True)


class Salida(BaseModel):
    """Permite construir respuestas desde instancias ORM."""
    model_config = ConfigDict(from_attributes=True)


class CambioParcial(Entrada):
    @model_validator(mode='after')
    def validar_cambios(self):
        if not self.model_fields_set:
            raise ValueError('Debe proporcionar al menos un campo')
        for campo in self.model_fields_set - {'apellido_materno'}:
            if getattr(self, campo) is None:
                raise ValueError(f'{campo} no admite null')
        return self


# Usuarios y autenticacion
class UsuarioRegistro(Entrada):
    nombre: Nombre
    apellido_paterno: Apellido
    apellido_materno: Apellido | None = None
    correo: Correo
    contrasena: SecretStr = Field(min_length=8, max_length=128)

    @field_validator('contrasena')
    @classmethod
    def validar_contrasena(cls, valor):
        if not valor.get_secret_value().strip():
            raise ValueError('La contrasena no puede estar vacia')
        return valor


class UsuarioActualizar(CambioParcial):
    nombre: Nombre | None = None
    apellido_paterno: Apellido | None = None
    apellido_materno: Apellido | None = None
    correo: Correo | None = None


class CambioContrasena(Entrada):
    contrasena_actual: SecretStr = Field(min_length=1, max_length=128)
    contrasena_nueva: SecretStr = Field(min_length=8, max_length=128)

    @field_validator('contrasena_nueva')
    @classmethod
    def validar_nueva(cls, valor):
        if not valor.get_secret_value().strip():
            raise ValueError('La contrasena no puede estar vacia')
        return valor


class UsuarioResumen(Salida):
    id_usuario: Id
    nombre: str
    apellido_paterno: str
    apellido_materno: str | None
    tipo_imagen: MimeImagen | None


class UsuarioRespuesta(UsuarioResumen):
    correo: str
    rol: Rol
    estado: bool
    fecha_registro: datetime


class LoginSolicitud(Entrada):
    correo: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=150)]
    contrasena: SecretStr = Field(min_length=1, max_length=128)

    @field_validator('correo')
    @classmethod
    def validar_correo(cls, valor):
        # Las cuentas ficticias del script SQL usan un dominio reservado.
        demos = {f'{nombre}@saludmayor.example' for nombre in ('admin', 'maria', 'carlos', 'ana')}
        if valor.lower() in demos:
            return valor.lower()
        return TypeAdapter(EmailStr).validate_python(valor)


class RegistroRespuesta(UsuarioRespuesta):
    clave_recuperacion: str


class RenovarRecuperacion(Entrada):
    contrasena: SecretStr = Field(min_length=1, max_length=128)


class RecuperarContrasena(CambioContrasena):
    correo: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=150)]
    # El campo heredado representa la clave de recuperacion, no la contrasena.


class LoginRespuesta(Salida):
    """Respuesta web: el token se entrega en una cookie HttpOnly, no aqui."""
    usuario: UsuarioRespuesta
    fecha_expiracion: datetime


class TokenRespuesta(Salida):
    """Contrato para clientes nativos, si se habilita el transporte Bearer."""
    access_token: str
    token_type: Literal['bearer'] = 'bearer'
    expires_in: Annotated[int, Field(gt=0)]


# Categorias y publicaciones
class CategoriaGuardar(Entrada):
    nombre: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=80)]
    descripcion: Annotated[str, StringConstraints(strip_whitespace=True, max_length=255)] | None = None

    @field_validator('descripcion')
    @classmethod
    def normalizar_descripcion(cls, valor):
        return valor or None


class CategoriaEstadoActualizar(Entrada):
    estado: Annotated[bool, Field(strict=True)]


class CategoriaRespuesta(Salida):
    id_categoria: Id
    nombre: str
    descripcion: str | None
    estado: bool


class BlogCrear(Entrada):
    id_categoria: Id
    titulo: Titulo
    descripcion: Descripcion
    contenido: Contenido


class BlogActualizar(CambioParcial):
    id_categoria: Id | None = None
    titulo: Titulo | None = None
    descripcion: Descripcion | None = None
    contenido: Contenido | None = None


class BlogResumen(Salida):
    id_blog: Id
    id_usuario: Id
    id_categoria: Id
    titulo: str
    descripcion: str
    tipo_imagen: MimeImagen | None
    fecha_publicacion: datetime
    fecha_actualizacion: datetime | None
    autor: UsuarioResumen
    categoria: CategoriaRespuesta


class BlogRespuesta(BlogResumen):
    contenido: str


# Comentarios: id_blog proviene de la ruta; id_usuario de la sesion.
class ComentarioCrear(Entrada):
    comentario: TextoCorto


class ComentarioRespuesta(Salida):
    id_comentario: Id
    id_usuario: Id
    id_blog: Id
    comentario: str
    fecha_comentario: datetime
    usuario: UsuarioResumen


# Valoraciones: id_blog proviene de la ruta.
class ValoracionGuardar(Entrada):
    puntuacion: Puntuacion


class ValoracionRespuesta(Salida):
    id_valoracion: Id
    id_usuario: Id
    id_blog: Id
    puntuacion: Puntuacion
    fecha_valoracion: datetime


class ValoracionResumen(Salida):
    id_blog: Id
    promedio: Annotated[float, Field(ge=1, le=5)] | None
    total: Annotated[int, Field(ge=0)]
    mi_puntuacion: Puntuacion | None = None


# Reacciones: id_comentario proviene de la ruta.
class TipoReaccionRespuesta(Salida):
    id_tipo_reaccion: Id
    nombre: str
    emoji: str
    estado: bool


class ReaccionGuardar(Entrada):
    id_tipo_reaccion: Id


class ReaccionRespuesta(Salida):
    id_reaccion: Id
    id_usuario: Id
    id_comentario: Id
    id_tipo_reaccion: Id
    fecha_reaccion: datetime
    tipo_reaccion: TipoReaccionRespuesta


class ReaccionConteo(Salida):
    tipo_reaccion: TipoReaccionRespuesta
    total: Annotated[int, Field(ge=0)]


class ReaccionResumen(Salida):
    id_comentario: Id
    mi_reaccion: Id | None = None
    resultados: list[ReaccionConteo]


# Mensajes: el emisor siempre se obtiene de la sesion.
class MensajeCrear(Entrada):
    id_receptor: Id
    mensaje: TextoCorto


class MensajeRespuesta(Salida):
    id_mensaje: Id
    id_emisor: Id
    id_receptor: Id
    mensaje: str
    fecha_envio: datetime
    leido: bool
    fecha_lectura: datetime | None
    emisor: UsuarioResumen
    receptor: UsuarioResumen


# Configuracion: el logotipo se transmite mediante un endpoint de imagen.
class ConfiguracionActualizar(Entrada):
    nombre_app: Nombre


class ConfiguracionRespuesta(Salida):
    id_configuracion: Literal[1]
    nombre_app: str
    tipo_imagen: MimeImagen | None
    fecha_actualizacion: datetime


class SesionRespuesta(Salida):
    id_sesion: Annotated[int, Field(ge=1, le=18446744073709551615)]
    fecha_inicio: datetime
    fecha_expiracion: datetime
    fecha_cierre: datetime | None
    revocada: bool


class RespuestaMensaje(Salida):
    mensaje: str


class UsuarioEstadoActualizar(Entrada):
    """Cambio de estado exclusivo para administradores."""
    estado: Annotated[bool, Field(strict=True)]


class ConversacionRespuesta(Salida):
    usuario: UsuarioResumen
    ultimo_mensaje: MensajeRespuesta
    no_leidos: Annotated[int, Field(ge=0)]


class MensajesPendientes(Salida):
    total: Annotated[int, Field(ge=0)]
