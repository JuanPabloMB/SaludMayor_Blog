"""Catalogo privado y administracion de categorias."""
from typing import Annotated
from fastapi import APIRouter, Depends
from core.dependencies import Db, get_current_user, require_admin
from models import Usuario
from schemas import CategoriaRespuesta, CategoriaGuardar, CategoriaEstadoActualizar
from services import categoria_service as servicio

router = APIRouter(prefix='/categorias', tags=['Categorias'])
Actual = Annotated[Usuario, Depends(get_current_user)]
Admin = Annotated[Usuario, Depends(require_admin)]


@router.get('', response_model=list[CategoriaRespuesta])
def listar(db: Db, usuario: Actual):
    return servicio.listar(db)


@router.get('/admin', response_model=list[CategoriaRespuesta])
def listar_admin(db: Db, administrador: Admin):
    return servicio.listar(db, solo_activas=False)


@router.post('/admin', response_model=CategoriaRespuesta, status_code=201)
def crear(datos: CategoriaGuardar, db: Db, administrador: Admin):
    return servicio.crear(db, datos)


@router.patch('/admin/{id_categoria}', response_model=CategoriaRespuesta)
def editar(id_categoria: int, datos: CategoriaGuardar, db: Db, administrador: Admin):
    return servicio.editar(db, id_categoria, datos)


@router.patch('/admin/{id_categoria}/estado', response_model=CategoriaRespuesta)
def cambiar_estado(id_categoria: int, datos: CategoriaEstadoActualizar, db: Db, administrador: Admin):
    return servicio.cambiar_estado(db, id_categoria, datos.estado)
