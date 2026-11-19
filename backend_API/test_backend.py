"""Regresion completa; ejecutar contra BD de pruebas con Uvicorn activo."""
import subprocess
import sys
from pathlib import Path
from time import sleep

PRUEBAS = ('test_connection.py','test_models.py','test_schemas.py','test_http_security.py',
           'test_auth.py','test_usuarios.py','test_roles.py','test_blog.py','test_comentarios.py',
           'test_comentarios_eliminacion.py','test_valoraciones.py','test_reacciones.py',
           'test_mensajes.py','test_configuracion.py','test_categorias_panel.py','test_recuperacion.py')


def main():
    raiz = Path(__file__).resolve().parent
    if input('Usa una BD de pruebas respaldada. Escribe PRUEBAS para continuar: ').strip() != 'PRUEBAS':
        return 1
    aprobadas = 0
    for i, archivo in enumerate(PRUEBAS):
        if i >= 4:
            print('Esperando 61 segundos para respetar el limite de autenticacion...', flush=True)
            sleep(61)
        print(f'\n=== {archivo} ===', flush=True)
        resultado = subprocess.run([sys.executable, str(raiz / archivo)], cwd=raiz)
        if resultado.returncode:
            print(f'REGRESION INTERRUMPIDA: {archivo}; {aprobadas}/{len(PRUEBAS)} scripts aprobados', flush=True)
            return 1
        aprobadas += 1
    print(f'REGRESION COMPLETA EXITOSA: {aprobadas}/{len(PRUEBAS)} scripts')
    return 0


if __name__ == '__main__':
    sys.exit(main())
