"""Operaciones de cuentas y perfiles."""
from fastapi import HTTPException
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from models import Usuario, Sesion
from schemas import UsuarioRegistro, UsuarioActualizar, CambioContrasena
from core.security import hash_password, verify_password, utc_now

def guardar(db: Session, usuario: Usuario):
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        if getattr(exc.orig, 'args', (None,))[0] == 1062:
            raise HTTPException(409, 'Correo ya registrado') from None
        raise
    db.refresh(usuario)
    return usuario

def registrar(db: Session, datos: UsuarioRegistro, clave=None):
    usuario = Usuario(**datos.model_dump(exclude={'contrasena'}),
                      contrasena=hash_password(datos.contrasena.get_secret_value()),
                      rol='usuario', estado=True, recuperacion_hash=hash_password(clave) if clave else None)
    db.add(usuario)
    return guardar(db, usuario)

def actualizar(db: Session, usuario: Usuario, datos: UsuarioActualizar):
    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(usuario, campo, valor)
    return guardar(db, usuario)

def cambiar_contrasena(db: Session, usuario: Usuario, datos: CambioContrasena):
    # Bloquea la cuenta durante la modificacion y vuelve a leer su hash.
    usuario = db.scalar(select(Usuario).where(Usuario.id_usuario == usuario.id_usuario)
                        .with_for_update().execution_options(populate_existing=True))
    db.refresh(usuario, ['contrasena'])
    if not verify_password(datos.contrasena_actual.get_secret_value(), usuario.contrasena):
        raise HTTPException(400, 'Contrasena actual incorrecta')
    usuario.contrasena = hash_password(datos.contrasena_nueva.get_secret_value())
    db.execute(update(Sesion).where(Sesion.id_usuario == usuario.id_usuario,
               Sesion.revocada.is_(False)).values(revocada=True, fecha_cierre=utc_now()))
    db.commit()


def cambiar_estado(db: Session, administrador: Usuario, id_usuario: int, estado: bool):
    """Conserva la cuenta y revoca sesiones al desactivarla."""
    cuenta = db.scalar(select(Usuario).where(Usuario.id_usuario == id_usuario)
                      .with_for_update().execution_options(populate_existing=True))
    if cuenta is None:
        raise HTTPException(404, 'Usuario no encontrado')
    if cuenta.id_usuario == administrador.id_usuario or cuenta.rol == 'administrador':
        raise HTTPException(403, 'No se permite modificar el estado de administradores')
    cuenta.estado = estado
    if not estado:
        db.execute(update(Sesion).where(Sesion.id_usuario == id_usuario,
                   Sesion.revocada.is_(False)).values(revocada=True, fecha_cierre=utc_now()))
    return guardar(db, cuenta)
