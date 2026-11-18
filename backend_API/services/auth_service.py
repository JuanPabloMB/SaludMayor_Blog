"""Operaciones de autenticacion y sesiones."""
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from models import Usuario, Sesion
from schemas import LoginSolicitud
from core.security import create_token, verify_password, DUMMY_HASH, utc_now

def iniciar_sesion(db: Session, datos: LoginSolicitud, transport: str):
    usuario = db.scalar(select(Usuario).where(Usuario.correo == datos.correo))
    hashed = usuario.contrasena if usuario else DUMMY_HASH
    valido = verify_password(datos.contrasena.get_secret_value(), hashed)
    if not usuario or not valido or not usuario.estado:
        raise HTTPException(401, 'Correo o contrasena incorrectos')
    token, jti, inicio, exp = create_token(usuario.id_usuario, transport)
    sesion = Sesion(id_usuario=usuario.id_usuario, identificador_token=jti,
                   fecha_inicio=inicio, fecha_expiracion=exp, revocada=False)
    db.add(sesion)
    db.commit()
    db.refresh(sesion)
    return usuario, sesion, token

def cerrar_sesion(db: Session, sesion: Sesion):
    sesion.revocada = True
    sesion.fecha_cierre = utc_now()
    db.commit()
