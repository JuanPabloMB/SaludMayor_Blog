"""Punto de entrada de la API de SaludMayor Blog."""
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError
from core.config import settings
from routers.auth import router as auth_router

app = FastAPI(title=settings.APP_NAME, version=settings.APP_VERSION, debug=False)
app.add_middleware(CORSMiddleware, allow_origins=settings.CORS_ORIGINS,
                   allow_credentials=True, allow_methods=['GET','POST','PUT','PATCH','DELETE','OPTIONS'],
                   allow_headers=['Content-Type','Authorization'])

@app.exception_handler(RequestValidationError)
async def validation_error(request: Request, exc: RequestValidationError):
    return JSONResponse(status_code=422, content={'detail': 'Datos de solicitud invalidos'})

@app.exception_handler(SQLAlchemyError)
async def database_error(request: Request, exc: SQLAlchemyError):
    return JSONResponse(status_code=500, content={'detail': 'Error interno de base de datos'})

@app.get('/')
def inicio():
    return {'mensaje': 'API SaludMayor Blog', 'version': settings.APP_VERSION}

app.include_router(auth_router)

from routers.usuarios import router as usuarios_router
app.include_router(usuarios_router)

from routers.blog import router as blog_router
from routers.categorias import router as categorias_router
app.include_router(blog_router)
app.include_router(categorias_router)

from routers.comentarios import router as comentarios_router
app.include_router(comentarios_router)
