"""Endpoints de registro, perfil y directorio privado."""
from typing import Annotated
from fastapi import APIRouter, Depends, File, UploadFile, Response, Request, HTTPException, Query
from sqlalchemy import select
from core.dependencies import Db, get_current_user, require_admin, COOKIE_NAME
from core.config import settings
from models import Usuario
from schemas import (UsuarioRegistro, UsuarioActualizar, UsuarioRespuesta,
                     UsuarioResumen, CambioContrasena, RespuestaMensaje, UsuarioEstadoActualizar)
from services import usuario_service as servicio
from services.imagen_service import validar_imagen

router = APIRouter(prefix='/usuarios', tags=['Usuarios'])
Actual = Annotated[Usuario, Depends(get_current_user)]

@router.post('/registro', response_model=UsuarioRespuesta, status_code=201)
def registro(datos: UsuarioRegistro, db: Db):
    return servicio.registrar(db, datos)

@router.get('/me', response_model=UsuarioRespuesta)
def perfil(usuario: Actual):
    return usuario

@router.patch('/me', response_model=UsuarioRespuesta)
def editar(datos: UsuarioActualizar, db: Db, usuario: Actual):
    return servicio.actualizar(db, usuario, datos)

@router.put('/me/contrasena', response_model=RespuestaMensaje)
def contrasena(datos: CambioContrasena, db: Db, usuario: Actual, request: Request, response: Response):
    servicio.cambiar_contrasena(db, usuario, datos)
    response.delete_cookie(COOKIE_NAME, path='/', httponly=True, samesite='lax', secure=settings.COOKIE_SECURE or request.url.scheme == 'https')
    return RespuestaMensaje(mensaje='Contrasena actualizada. Inicie sesion nuevamente')

@router.put('/me/foto', response_model=UsuarioRespuesta)
def subir_foto(db: Db, usuario: Actual, archivo: Annotated[UploadFile, File()]):
    usuario.foto_perfil, usuario.tipo_imagen = validar_imagen(archivo, settings.MAX_PROFILE_IMAGE_SIZE)
    return servicio.guardar(db, usuario)

@router.delete('/me/foto', response_model=UsuarioRespuesta)
def eliminar_foto(db: Db, usuario: Actual):
    usuario.foto_perfil = usuario.tipo_imagen = None
    return servicio.guardar(db, usuario)

@router.get('', response_model=list[UsuarioResumen])
def directorio(db: Db, usuario: Actual, offset: int = Query(0, ge=0), limite: int = Query(50, ge=1, le=100)):
    return db.scalars(select(Usuario).where(Usuario.estado.is_(True), Usuario.id_usuario != usuario.id_usuario)
                      .order_by(Usuario.nombre, Usuario.id_usuario).offset(offset).limit(limite)).all()

@router.get('/{id_usuario}/foto')
def foto(id_usuario: int, db: Db, usuario: Actual):
    cuenta = db.get(Usuario, id_usuario)
    if not cuenta or not cuenta.estado or not cuenta.foto_perfil:
        raise HTTPException(404, 'Fotografia no encontrada')
    return Response(cuenta.foto_perfil, media_type=cuenta.tipo_imagen,
                    headers={'Cache-Control':'no-store', 'X-Content-Type-Options':'nosniff'})


Admin = Annotated[Usuario, Depends(require_admin)]

@router.get('/admin', response_model=list[UsuarioRespuesta])
def listar_cuentas(db: Db, administrador: Admin, offset: int = Query(0, ge=0), limite: int = Query(50, ge=1, le=100)):
    return db.scalars(select(Usuario).order_by(Usuario.id_usuario).offset(offset).limit(limite)).all()

@router.get('/admin/{id_usuario}', response_model=UsuarioRespuesta)
def consultar_cuenta(id_usuario: int, db: Db, administrador: Admin):
    cuenta = db.get(Usuario, id_usuario)
    if cuenta is None:
        raise HTTPException(404, 'Usuario no encontrado')
    return cuenta

@router.patch('/admin/{id_usuario}/estado', response_model=UsuarioRespuesta)
def modificar_estado(id_usuario: int, datos: UsuarioEstadoActualizar, db: Db, administrador: Admin):
    return servicio.cambiar_estado(db, administrador, id_usuario, datos.estado)
