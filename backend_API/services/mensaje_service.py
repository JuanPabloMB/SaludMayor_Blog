"""Operaciones privadas de mensajeria; nunca aceptan un emisor externo."""
from fastapi import HTTPException
from sqlalchemy import and_, or_, select, func, case
from sqlalchemy.orm import joinedload
from core.security import utc_now
from models import Mensaje, Usuario


def enviar(db, datos, uid):
    if datos.id_receptor == uid:
        raise HTTPException(422, 'No puedes enviarte mensajes')
    receptor = db.scalar(select(Usuario).where(
        Usuario.id_usuario == datos.id_receptor, Usuario.estado.is_(True)))
    if receptor is None:
        raise HTTPException(404, 'Destinatario no disponible')
    msg = Mensaje(id_emisor=uid, id_receptor=datos.id_receptor,
                  mensaje=datos.mensaje, fecha_envio=utc_now(), leido=False)
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return msg


def participantes(uid):
    return or_(Mensaje.id_emisor == uid, Mensaje.id_receptor == uid)


def listar(db, uid, otro, bandeja, offset, limite):
    stmt = select(Mensaje).options(joinedload(Mensaje.emisor), joinedload(Mensaje.receptor))
    stmt = stmt.where(participantes(uid))
    if otro is not None:
        stmt = stmt.where(or_(
            and_(Mensaje.id_emisor == uid, Mensaje.id_receptor == otro),
            and_(Mensaje.id_receptor == uid, Mensaje.id_emisor == otro)))
    if bandeja == 'recibidos':
        stmt = stmt.where(Mensaje.id_receptor == uid)
    elif bandeja == 'enviados':
        stmt = stmt.where(Mensaje.id_emisor == uid)
    return db.scalars(stmt.order_by(Mensaje.fecha_envio.desc(), Mensaje.id_mensaje.desc())
                      .offset(offset).limit(limite)).all()


def conversaciones(db, uid, offset, limite):
    otro = case((Mensaje.id_emisor == uid, Mensaje.id_receptor), else_=Mensaje.id_emisor)
    # Un registro por interlocutor; el orden se determina por el ultimo mensaje.
    sub = select(otro.label('otro'), Mensaje.id_mensaje.label('mid'),
                 func.row_number().over(partition_by=otro, order_by=(
                     Mensaje.fecha_envio.desc(), Mensaje.id_mensaje.desc())).label('rn'),
                 func.sum(case((and_(Mensaje.id_receptor == uid, Mensaje.leido.is_(False)), 1),
                               else_=0)).over(partition_by=otro).label('no_leidos'))\
        .where(participantes(uid)).subquery()
    stmt = select(Usuario, Mensaje, sub.c.no_leidos).select_from(sub)\
        .join(Usuario, Usuario.id_usuario == sub.c.otro)\
        .join(Mensaje, Mensaje.id_mensaje == sub.c.mid)\
        .options(joinedload(Mensaje.emisor), joinedload(Mensaje.receptor))\
        .where(sub.c.rn == 1).order_by(Mensaje.fecha_envio.desc(), Mensaje.id_mensaje.desc())\
        .offset(offset).limit(limite)
    return [dict(usuario=u, ultimo_mensaje=m, no_leidos=int(n)) for u,m,n in db.execute(stmt)]


def pendientes(db, uid):
    return db.scalar(select(func.count(Mensaje.id_mensaje)).where(
        Mensaje.id_receptor == uid, Mensaje.leido.is_(False)))


def obtener(db, mid, uid, bloquear=False):
    stmt = select(Mensaje).where(Mensaje.id_mensaje == mid, participantes(uid))
    if bloquear:
        stmt = stmt.with_for_update()
    msg = db.scalar(stmt)
    if msg is None:
        raise HTTPException(404, 'Mensaje no encontrado')
    return msg


def leer(db, mid, uid):
    msg = obtener(db, mid, uid, True)
    if msg.id_receptor != uid:
        raise HTTPException(403, 'Solo el receptor puede marcar como leido')
    if not msg.leido:
        msg.leido = True
        msg.fecha_lectura = max(utc_now(), msg.fecha_envio)
        db.commit()
        db.refresh(msg)
    return msg
