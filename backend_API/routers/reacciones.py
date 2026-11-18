"""Catalogo y reacciones privadas a comentarios."""
from typing import Annotated
from fastapi import APIRouter, Depends, Path
from core.dependencies import Db, get_current_user
from models import Usuario
from schemas import TipoReaccionRespuesta, ReaccionGuardar, ReaccionResumen
from services import reaccion_service as servicio

router = APIRouter(tags=['Reacciones'])
Actual = Annotated[Usuario, Depends(get_current_user)]
IdComentario = Annotated[int, Path(ge=1, le=4294967295)]
RUTA = '/comentarios/{id_comentario}/reacciones'


@router.get('/tipos-reaccion', response_model=list[TipoReaccionRespuesta])
def catalogo(db: Db, usuario: Actual):
    return servicio.tipos(db)


@router.get(RUTA, response_model=ReaccionResumen)
def consultar(id_comentario: IdComentario, db: Db, usuario: Actual):
    return servicio.resumen(db, id_comentario, usuario.id_usuario)


@router.put(RUTA, response_model=ReaccionResumen)
def guardar(id_comentario: IdComentario, datos: ReaccionGuardar, db: Db, usuario: Actual):
    return servicio.guardar(db, id_comentario, datos, usuario)


@router.delete(RUTA, response_model=ReaccionResumen)
def eliminar(id_comentario: IdComentario, db: Db, usuario: Actual):
    return servicio.eliminar(db, id_comentario, usuario)
