import secrets
from fastapi import HTTPException
from sqlalchemy import select, update
from models import Usuario, Sesion
from core.security import hash_password, verify_password, DUMMY_HASH, utc_now


def nueva_clave():
    return secrets.token_hex(16)


def renovar(db, usuario, datos):
    cuenta = db.scalar(select(Usuario).where(Usuario.id_usuario == usuario.id_usuario)
                       .with_for_update().execution_options(populate_existing=True))
    db.refresh(cuenta, ['contrasena'])
    if not cuenta.estado or not verify_password(datos.contrasena.get_secret_value(), cuenta.contrasena):
        raise HTTPException(400, 'Contrasena incorrecta')
    clave = nueva_clave()
    cuenta.recuperacion_hash = hash_password(clave)
    db.commit()
    return clave


def recuperar(db, datos):
    cuenta = db.scalar(select(Usuario).where(Usuario.correo == datos.correo).with_for_update())
    hashed = cuenta.recuperacion_hash if cuenta else None
    valido = verify_password(datos.contrasena_actual.get_secret_value().strip().lower(), hashed or DUMMY_HASH)
    if not cuenta or not cuenta.estado or not hashed or not valido:
        raise HTTPException(400, 'Correo o clave de recuperacion incorrectos')
    cuenta.contrasena = hash_password(datos.contrasena_nueva.get_secret_value())
    cuenta.recuperacion_hash = None
    db.execute(update(Sesion).where(Sesion.id_usuario == cuenta.id_usuario,
               Sesion.revocada.is_(False)).values(revocada=True, fecha_cierre=utc_now()))
    db.commit()
