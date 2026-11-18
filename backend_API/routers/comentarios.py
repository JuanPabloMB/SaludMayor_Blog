"""Endpoints de comentarios; ambos requieren autenticacion."""
from typing import Annotated
from fastapi import APIRouter, Depends, Path, Query
from core.dependencies import Db, get_current_user
from models import Usuario
from schemas import ComentarioCrear, ComentarioRespuesta
from services import comentario_service as servicio

router = APIRouter(prefix='/blog/{id_blog}/comentarios', tags=['Comentarios'])
Actual = Annotated[Usuario, Depends(get_current_user)]
IdBlog = Annotated[int, Path(ge=1, le=4294967295)]


@router.get('', response_model=list[ComentarioRespuesta])
def listar(id_blog: IdBlog, db: Db, usuario: Actual,
           offset: int = Query(0, ge=0), limite: int = Query(50, ge=1, le=100)):
    return servicio.listar(db, id_blog, offset, limite)


@router.post('', response_model=ComentarioRespuesta, status_code=201)
def crear(id_blog: IdBlog, datos: ComentarioCrear, db: Db, usuario: Actual):
    return servicio.crear(db, id_blog, datos, usuario)
