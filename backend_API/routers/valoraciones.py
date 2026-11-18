"""Consulta y registro de valoraciones de publicaciones privadas."""
from typing import Annotated
from fastapi import APIRouter, Depends, Path
from core.dependencies import Db, get_current_user
from models import Usuario
from schemas import ValoracionGuardar, ValoracionResumen
from services import valoracion_service as servicio

router = APIRouter(prefix='/blog/{id_blog}/valoraciones', tags=['Valoraciones'])
Actual = Annotated[Usuario, Depends(get_current_user)]
IdBlog = Annotated[int, Path(ge=1, le=4294967295)]


@router.get('', response_model=ValoracionResumen)
def consultar(id_blog: IdBlog, db: Db, usuario: Actual):
    return servicio.resumen(db, id_blog, usuario.id_usuario)


@router.put('', response_model=ValoracionResumen)
def guardar(id_blog: IdBlog, datos: ValoracionGuardar, db: Db, usuario: Actual):
    return servicio.guardar(db, id_blog, datos, usuario)
