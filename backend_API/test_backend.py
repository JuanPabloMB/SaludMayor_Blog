"""Ejecuta la regresion completa en orden; requiere Uvicorn activo."""
import subprocess
import sys
from pathlib import Path

PRUEBAS = ('test_connection.py','test_models.py','test_schemas.py','test_auth.py',
           'test_usuarios.py','test_roles.py','test_blog.py','test_comentarios.py',
           'test_valoraciones.py','test_reacciones.py','test_mensajes.py','test_configuracion.py')


def main():
    raiz = Path(__file__).resolve().parent
    for archivo in PRUEBAS:
        print(f'\n=== {archivo} ===', flush=True)
        resultado = subprocess.run([sys.executable, str(raiz / archivo)], cwd=raiz)
        if resultado.returncode:
            print(f'REGRESION INTERRUMPIDA: {archivo}', flush=True)
            return 1
    print('REGRESION COMPLETA EXITOSA: 12/12 scripts')
    return 0


if __name__ == '__main__':
    sys.exit(main())
