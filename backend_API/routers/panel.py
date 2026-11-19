"""Panel administrativo de solo lectura."""
from typing import Annotated
from fastapi import APIRouter, Depends, Response
from core.dependencies import Db, require_admin
from models import Usuario
from services.panel_service import resumen

router = APIRouter(prefix='/panel', tags=['Panel administrativo'])


@router.get('/resumen')
def consultar(db: Db, usuario: Annotated[Usuario, Depends(require_admin)],
              response: Response):
    response.headers['Cache-Control'] = 'no-store'
    return resumen(db)
