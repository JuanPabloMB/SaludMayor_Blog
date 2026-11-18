"""Dependencias de autenticacion y proteccion CSRF."""
from typing import Annotated
import jwt
from fastapi import Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.orm import Session
from database import get_db
from models import Usuario, Sesion
from core.config import settings
from core.security import decode_token, utc_now

COOKIE_NAME = 'saludmayor_session'
Db = Annotated[Session, Depends(get_db)]

def unauthorized():
    return HTTPException(401, 'Sesion invalida o expirada', headers={'WWW-Authenticate':'Bearer'})

def validar_origen(request: Request):
    origin = request.headers.get('origin')
    allowed = set(settings.CORS_ORIGINS) | {str(request.base_url).rstrip('/')}
    if origin not in allowed:
        raise HTTPException(403, 'Origen no autorizado')

def get_current_session(request: Request, db: Db) -> Sesion:
    auth = request.headers.get('authorization')
    cookie = request.cookies.get(COOKIE_NAME)
    if auth:
        if cookie or not auth.lower().startswith('bearer '):
            raise unauthorized()
        token, transport = auth[7:], 'bearer'
    else:
        token, transport = cookie, 'cookie'
        if token and request.method not in {'GET','HEAD','OPTIONS'}:
            validar_origen(request)
    if not token:
        raise unauthorized()
    try:
        claims = decode_token(token, transport)
    except (jwt.InvalidTokenError, ValueError, TypeError):
        raise unauthorized() from None
    sesion = db.scalar(select(Sesion).join(Usuario).where(
        Sesion.identificador_token == claims['jti'], Sesion.id_usuario == int(claims['sub']),
        Sesion.revocada.is_(False), Sesion.fecha_expiracion > utc_now(), Usuario.estado.is_(True)))
    if sesion is None:
        raise unauthorized()
    return sesion

def get_current_user(sesion: Annotated[Sesion, Depends(get_current_session)]) -> Usuario:
    return sesion.usuario

def require_admin(usuario: Annotated[Usuario, Depends(get_current_user)]) -> Usuario:
    if usuario.rol != 'administrador':
        raise HTTPException(403, 'Permisos insuficientes')
    return usuario
