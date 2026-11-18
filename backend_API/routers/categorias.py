"""Catalogo privado de categorias activas."""
from typing import Annotated
from fastapi import APIRouter, Depends
from sqlalchemy import select
from core.dependencies import Db, get_current_user
from models import Categoria, Usuario
from schemas import CategoriaRespuesta

router = APIRouter(prefix='/categorias', tags=['Categorias'])

@router.get('', response_model=list[CategoriaRespuesta])
def listar(db: Db, usuario: Annotated[Usuario, Depends(get_current_user)]):
    return db.scalars(select(Categoria).where(Categoria.estado.is_(True)).order_by(Categoria.nombre)).all()
