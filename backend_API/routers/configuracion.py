"""Identidad visual publica; modificaciones exclusivas del administrador."""
from typing import Annotated
from fastapi import APIRouter, Depends, File, HTTPException, Response, UploadFile
from core.dependencies import Db, require_admin
from core.config import settings
from models import Usuario
from schemas import ConfiguracionActualizar, ConfiguracionRespuesta
from services import configuracion_service as servicio
from services.imagen_service import validar_imagen

router = APIRouter(prefix='/configuracion', tags=['Configuracion'])
Admin = Annotated[Usuario, Depends(require_admin)]


@router.get('', response_model=ConfiguracionRespuesta)
def obtener(db: Db, response: Response):
    response.headers['Cache-Control'] = 'no-store'
    return servicio.obtener(db)


@router.patch('', response_model=ConfiguracionRespuesta)
def actualizar(datos: ConfiguracionActualizar, db: Db, usuario: Admin):
    conf = servicio.obtener(db, bloquear=True)
    conf.nombre_app = datos.nombre_app
    return servicio.guardar(db, conf, usuario)


@router.get('/logotipo')
def logotipo(db: Db):
    conf = servicio.obtener(db)
    if conf.logotipo is None:
        raise HTTPException(404, 'Logotipo no encontrado', headers={'Cache-Control': 'no-store'})
    return Response(content=conf.logotipo, media_type=conf.tipo_imagen,
                    headers={'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff'})


@router.put('/logotipo', response_model=ConfiguracionRespuesta)
def subir_logotipo(db: Db, usuario: Admin, archivo: Annotated[UploadFile, File()]):
    contenido, mime = validar_imagen(archivo, settings.MAX_LOGO_IMAGE_SIZE)
    conf = servicio.obtener(db, bloquear=True)
    conf.logotipo, conf.tipo_imagen = contenido, mime
    return servicio.guardar(db, conf, usuario)


@router.delete('/logotipo', response_model=ConfiguracionRespuesta)
def eliminar_logotipo(db: Db, usuario: Admin):
    conf = servicio.obtener(db, bloquear=True)
    conf.logotipo = conf.tipo_imagen = None
    return servicio.guardar(db, conf, usuario)
