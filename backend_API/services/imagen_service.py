"""Validacion de imagenes reutilizable para perfil, blog y logotipo."""
from io import BytesIO
from PIL import Image, UnidentifiedImageError
from fastapi import HTTPException, UploadFile

FORMATOS = {'JPEG': 'image/jpeg', 'PNG': 'image/png', 'WEBP': 'image/webp'}

def validar_imagen(archivo: UploadFile, limite: int) -> tuple[bytes, str]:
    datos = archivo.file.read(limite + 1)
    if len(datos) > limite:
        raise HTTPException(413, 'Imagen demasiado grande')
    try:
        with Image.open(BytesIO(datos)) as im:
            mime = FORMATOS.get(im.format)
            if not mime or mime != archivo.content_type:
                raise HTTPException(415, 'Formato de imagen no admitido')
            if im.width * im.height > 16000000 or getattr(im, 'is_animated', False):
                raise HTTPException(422, 'Imagen animada o dimensiones excesivas')
            im.verify()
        with Image.open(BytesIO(datos)) as im:
            im.load()
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError, SyntaxError):
        raise HTTPException(422, 'Imagen invalida') from None
    return datos, mime
