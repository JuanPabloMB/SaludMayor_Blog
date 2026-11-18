
"""
Archivo: test_connection.py

Descripcion:
Comprueba la conexion con MySQL y verifica
la existencia de las tablas de SaludMayor Blog.

Autor:
Equipo SaludMayor.
"""

from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from database import engine


TABLAS_ESPERADAS = {
    "usuario",
    "categorias",
    "blog",
    "comentarios",
    "valoraciones",
    "tipo_reaccion",
    "reacciones",
    "mensajes",
    "configuracion",
    "sesiones"
}


def test_connection() -> bool:
    """Realiza las pruebas de conexion."""

    try:

        with engine.connect() as connection:

            print("=" * 55)
            print("PRUEBA DE CONEXION - SALUDMAYOR BLOG")
            print("=" * 55)

            # Informacion del servidor
            resultado = connection.execute(
                text(
                    "SELECT DATABASE(), VERSION(), CURRENT_USER()"
                )
            ).one()

            print(f"Base de datos: {resultado[0]}")
            print(f"Version MySQL: {resultado[1]}")
            print(f"Usuario MySQL: {resultado[2]}")

            # Comprobar la codificacion
            charset = connection.execute(
                text("SELECT @@character_set_connection")
            ).scalar()

            print(f"Codificacion: {charset}")

            # Comprobar las tablas
            resultado_tablas = connection.execute(
                text("SHOW TABLES")
            )

            tablas = {
                fila[0] for fila in resultado_tablas
            }

            print("\nTABLAS ENCONTRADAS:")

            for tabla in sorted(tablas):
                print(f" - {tabla}")

            print(f"\nTotal de tablas: {len(tablas)}")

            faltantes = TABLAS_ESPERADAS - tablas

            if faltantes:
                print(
                    f"ERROR: Faltan tablas: {sorted(faltantes)}"
                )
                return False

            if resultado[0] != "saludmayor_blog":
                print("ERROR: Base de datos incorrecta.")
                return False

            if charset != "utf8mb4":
                print("ERROR: Codificacion incorrecta.")
                return False

            # Comprobar los datos iniciales
            usuarios = connection.execute(
                text("SELECT COUNT(*) FROM usuario")
            ).scalar()

            publicaciones = connection.execute(
                text("SELECT COUNT(*) FROM blog")
            ).scalar()

            categorias = connection.execute(
                text("SELECT COUNT(*) FROM categorias")
            ).scalar()

            print("\nDATOS REGISTRADOS:")
            print(f"Usuarios: {usuarios}")
            print(f"Publicaciones: {publicaciones}")
            print(f"Categorias: {categorias}")

            # Comprobar acentos
            print("\nPRUEBA DE ACENTOS:")

            resultado_categorias = connection.execute(
                text(
                    "SELECT nombre FROM categorias "
                    "ORDER BY id_categoria"
                )
            )

            for categoria in resultado_categorias:
                print(f" - {categoria[0]}")

            # Comprobar emojis
            print("\nPRUEBA DE EMOJIS:")

            resultado_reacciones = connection.execute(
                text(
                    "SELECT nombre, emoji FROM tipo_reaccion "
                    "ORDER BY id_tipo_reaccion"
                )
            )

            for reaccion in resultado_reacciones:
                print(f" - {reaccion[0]} {reaccion[1]}")

            print("\n" + "=" * 55)
            print("CONEXION EXITOSA")
            print("=" * 55)

            return True

    except SQLAlchemyError as error:

        print("\nERROR DE CONEXION CON MYSQL")
        print(error)

        return False

    finally:
        engine.dispose()


if __name__ == "__main__":
    raise SystemExit(0 if test_connection() else 1)
