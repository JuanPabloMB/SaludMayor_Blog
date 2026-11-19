"""Endpoints de autenticacion web y nativa."""
from typing import Annotated
from datetime import timezone
from fastapi import APIRouter, Depends, Request, Response
from core.config import settings
from core.dependencies import (Db, COOKIE_NAME, validar_origen, get_current_user, get_current_session)
from services.auth_service import iniciar_sesion, cerrar_sesion
from schemas import LoginSolicitud, LoginRespuesta, TokenRespuesta, UsuarioRespuesta, RespuestaMensaje
from models import Usuario, Sesion

router = APIRouter(prefix='/auth', tags=['Autenticacion'])

@router.post('/login', response_model=LoginRespuesta)
def login(datos: LoginSolicitud, request: Request, response: Response, db: Db):
    validar_origen(request)
    usuario, sesion, token = iniciar_sesion(db, datos, 'cookie')
    response.set_cookie(COOKIE_NAME, token, httponly=True, secure=settings.COOKIE_SECURE or request.url.scheme == 'https',
                        samesite='lax', max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60, path='/')
    response.headers['Cache-Control'] = 'no-store'
    return LoginRespuesta(usuario=UsuarioRespuesta.model_validate(usuario),
                          fecha_expiracion=sesion.fecha_expiracion.replace(tzinfo=timezone.utc))

@router.post('/token', response_model=TokenRespuesta)
def token_nativo(datos: LoginSolicitud, response: Response, db: Db):
    _, _, token = iniciar_sesion(db, datos, 'bearer')
    response.headers['Cache-Control'] = 'no-store'
    return TokenRespuesta(access_token=token, expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)

@router.get('/me', response_model=UsuarioRespuesta)
def me(response: Response, usuario: Annotated[Usuario, Depends(get_current_user)]):
    response.headers['Cache-Control'] = 'no-store'
    return usuario

@router.post('/logout', response_model=RespuestaMensaje)
def logout(request: Request, response: Response, db: Db,
           sesion: Annotated[Sesion, Depends(get_current_session)]):
    cerrar_sesion(db, sesion)
    response.delete_cookie(COOKIE_NAME, path='/', httponly=True, samesite='lax', secure=settings.COOKIE_SECURE or request.url.scheme == 'https')
    return RespuestaMensaje(mensaje='Sesion cerrada correctamente')
