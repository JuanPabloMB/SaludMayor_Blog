
"""Endpoints de comentarios de las publicaciones."""

from typing import Annotated

from fastapi import APIRouter, Depends, Path, Query, Response, status

from core.dependencies import Db, get_current_user
from models import Usuario
from schemas import ComentarioCrear, ComentarioRespuesta
from services import comentario_service as servicio


router = APIRouter(
    prefix="/blog/{id_blog}/comentarios",
    tags=["Comentarios"]
)


Actual = Annotated[
    Usuario,
    Depends(get_current_user)
]

IdBlog = Annotated[
    int,
    Path(ge=1, le=4294967295)
]

IdComentario = Annotated[
    int,
    Path(ge=1, le=4294967295)
]


@router.get(
    "",
    response_model=list[ComentarioRespuesta]
)
def listar(
    id_blog: IdBlog,
    db: Db,
    usuario: Actual,
    offset: int = Query(0, ge=0),
    limite: int = Query(50, ge=1, le=100)
):
    """Lista los comentarios activos de una publicacion."""

    return servicio.listar(
        db,
        id_blog,
        offset,
        limite
    )


@router.post(
    "",
    response_model=ComentarioRespuesta,
    status_code=status.HTTP_201_CREATED
)
def crear(
    id_blog: IdBlog,
    datos: ComentarioCrear,
    db: Db,
    usuario: Actual
):
    """Registra un comentario en una publicacion."""

    return servicio.crear(
        db,
        id_blog,
        datos,
        usuario
    )


@router.delete(
    "/{id_comentario}",
    status_code=status.HTTP_204_NO_CONTENT
)
def eliminar(
    id_blog: IdBlog,
    id_comentario: IdComentario,
    db: Db,
    usuario: Actual
):
    """
    Elimina logicamente un comentario.

    El propietario puede eliminar su comentario.
    El administrador puede moderar cualquier comentario.
    """

    servicio.eliminar(
        db,
        id_blog,
        id_comentario,
        usuario
    )

    return Response(
        status_code=status.HTTP_204_NO_CONTENT
    )
