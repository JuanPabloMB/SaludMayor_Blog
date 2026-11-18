"""API de mensajeria privada."""
from typing import Annotated, Literal
from fastapi import APIRouter, Depends, Path, Query, Response
from core.dependencies import Db, get_current_user
from models import Usuario
from schemas import MensajeCrear, MensajeRespuesta, ConversacionRespuesta, MensajesPendientes
from services import mensaje_service as servicio

router = APIRouter(prefix='/mensajes', tags=['Mensajes'])
Actual = Annotated[Usuario, Depends(get_current_user)]
IdMensaje = Annotated[int, Path(ge=1, le=4294967295)]
Offset = Annotated[int, Query(ge=0)]
Limite = Annotated[int, Query(ge=1, le=100)]

@router.post('', response_model=MensajeRespuesta, status_code=201)
def enviar(datos: MensajeCrear, db: Db, usuario: Actual, response: Response):
    response.headers['Cache-Control'] = 'private, no-store'
    return servicio.enviar(db, datos, usuario.id_usuario)

@router.get('', response_model=list[MensajeRespuesta])
def listar(db: Db, usuario: Actual, response: Response,
           id_usuario: Annotated[int | None, Query(ge=1, le=4294967295)] = None,
           bandeja: Literal['todos','enviados','recibidos'] = 'todos',
           offset: Offset = 0, limite: Limite = 50):
    response.headers['Cache-Control'] = 'private, no-store'
    return servicio.listar(db, usuario.id_usuario, id_usuario, bandeja, offset, limite)

@router.get('/conversaciones', response_model=list[ConversacionRespuesta])
def conversaciones(db: Db, usuario: Actual, response: Response,
                   offset: Offset = 0, limite: Limite = 50):
    response.headers['Cache-Control'] = 'private, no-store'
    return servicio.conversaciones(db, usuario.id_usuario, offset, limite)

@router.get('/no-leidos', response_model=MensajesPendientes)
def pendientes(db: Db, usuario: Actual, response: Response):
    response.headers['Cache-Control'] = 'private, no-store'
    return {'total': servicio.pendientes(db, usuario.id_usuario)}

@router.get('/{id_mensaje}', response_model=MensajeRespuesta)
def consultar(id_mensaje: IdMensaje, db: Db, usuario: Actual, response: Response):
    response.headers['Cache-Control'] = 'private, no-store'
    return servicio.obtener(db, id_mensaje, usuario.id_usuario)

@router.put('/{id_mensaje}/leido', response_model=MensajeRespuesta)
def leer(id_mensaje: IdMensaje, db: Db, usuario: Actual, response: Response):
    response.headers['Cache-Control'] = 'private, no-store'
    return servicio.leer(db, id_mensaje, usuario.id_usuario)
