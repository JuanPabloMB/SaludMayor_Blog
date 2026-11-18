"""CRUD privado de publicaciones y sus imagenes."""
from typing import Annotated
from fastapi import APIRouter, Depends, File, UploadFile, Response, HTTPException, Query, Path
from core.dependencies import Db, get_current_user, require_admin
from core.config import settings
from core.security import utc_now
from models import Usuario
from schemas import BlogCrear, BlogActualizar, BlogResumen, BlogRespuesta, RespuestaMensaje
from services import blog_service as servicio
from services.imagen_service import validar_imagen

router = APIRouter(prefix='/blog', tags=['Publicaciones'])
Actual = Annotated[Usuario, Depends(get_current_user)]
Admin = Annotated[Usuario, Depends(require_admin)]
IdBlog = Annotated[int, Path(ge=1, le=4294967295)]

@router.get('', response_model=list[BlogResumen])
def listar(db: Db, usuario: Actual, buscar: str | None = Query(None, max_length=150), id_categoria: int | None = Query(None, ge=1, le=4294967295), offset: int = Query(0, ge=0), limite: int = Query(50, ge=1, le=100)):
    return servicio.listar(db, buscar.strip() if buscar else None, id_categoria, offset, limite)

@router.post('', response_model=BlogRespuesta, status_code=201)
def crear(datos: BlogCrear, db: Db, usuario: Admin):
    return servicio.crear(db, datos, usuario)

@router.get('/{id_blog}', response_model=BlogRespuesta)
def detalle(id_blog: IdBlog, db: Db, usuario: Actual):
    return servicio.obtener(db, id_blog)

@router.patch('/{id_blog}', response_model=BlogRespuesta)
def editar(id_blog: IdBlog, datos: BlogActualizar, db: Db, usuario: Admin):
    return servicio.actualizar(db, id_blog, datos)

@router.delete('/{id_blog}', response_model=RespuestaMensaje)
def eliminar(id_blog: IdBlog, db: Db, usuario: Admin):
    servicio.eliminar(db, id_blog)
    return RespuestaMensaje(mensaje='Publicacion eliminada')

@router.get('/{id_blog}/imagen')
def imagen(id_blog: IdBlog, db: Db, usuario: Actual):
    blog = servicio.obtener(db, id_blog)
    if blog.imagen is None:
        raise HTTPException(404, 'Publicacion sin imagen')
    return Response(content=blog.imagen, media_type=blog.tipo_imagen, headers={'Cache-Control':'private, no-store', 'X-Content-Type-Options':'nosniff'})

@router.put('/{id_blog}/imagen', response_model=BlogRespuesta)
def subir_imagen(id_blog: IdBlog, db: Db, usuario: Admin, archivo: Annotated[UploadFile, File()]):
    datos, mime = validar_imagen(archivo, settings.MAX_POST_IMAGE_SIZE)
    blog = servicio.obtener(db, id_blog, bloquear=True)
    blog.imagen, blog.tipo_imagen = datos, mime
    blog.fecha_actualizacion = utc_now()
    return servicio.guardar(db, blog)

@router.delete('/{id_blog}/imagen', response_model=BlogRespuesta)
def eliminar_imagen(id_blog: IdBlog, db: Db, usuario: Admin):
    blog = servicio.obtener(db, id_blog, bloquear=True)
    blog.imagen = blog.tipo_imagen = None
    blog.fecha_actualizacion = utc_now()
    return servicio.guardar(db, blog)
