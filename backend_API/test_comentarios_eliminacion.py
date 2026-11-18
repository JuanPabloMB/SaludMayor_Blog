
"""Pruebas de eliminacion logica y permisos de comentarios."""

from uuid import uuid4

from sqlalchemy import select

from database import SessionLocal
from models import Comentario
from test_usuarios import call
from test_blog import login


def comprobar_estado(id_comentario, esperado):
    """Comprueba que el comentario permanezca en MySQL."""

    with SessionLocal() as db:
        comentario = db.scalar(
            select(Comentario).where(
                Comentario.id_comentario == id_comentario
            )
        )

        assert comentario is not None, (
            f"El comentario {id_comentario} no existe en MySQL"
        )

        assert comentario.estado is esperado, (
            f"Estado incorrecto para el comentario {id_comentario}: "
            f"esperado {esperado}, obtenido {comentario.estado}"
        )


def main():
    admin = login("administrador")
    normal = None
    ruta_blog = None

    try:
        administrador = call("/auth/me", token=admin)
        assert administrador["rol"] == "administrador"

        normal = login("usuario normal")
        usuario = call("/auth/me", token=normal)
        assert usuario["rol"] == "usuario"

        # Crear publicacion temporal para las pruebas.
        categorias = call("/categorias", token=admin)
        assert categorias

        publicacion = call(
            "/blog",
            "POST",
            {
                "id_categoria": categorias[0]["id_categoria"],
                "titulo": "Prueba eliminacion " + uuid4().hex,
                "descripcion": "Publicacion temporal de pruebas",
                "contenido": "Contenido temporal para probar comentarios",
            },
            admin,
            201,
        )

        id_blog = publicacion["id_blog"]
        ruta_blog = f"/blog/{id_blog}"
        endpoint = ruta_blog + "/comentarios"

        # Sin autenticacion no se permite eliminar.
        call(
            endpoint + "/1",
            "DELETE",
            expected=401,
        )

        # Crear comentario del usuario normal.
        propio = call(
            endpoint,
            "POST",
            {"comentario": "Comentario propio de prueba"},
            normal,
            201,
        )

        id_propio = propio["id_comentario"]

        assert propio["id_usuario"] == usuario["id_usuario"]

        # Crear comentario de otro usuario: administrador.
        ajeno = call(
            endpoint,
            "POST",
            {"comentario": "Comentario del administrador"},
            admin,
            201,
        )

        id_ajeno = ajeno["id_comentario"]

        # El usuario normal no puede eliminar comentarios ajenos.
        call(
            endpoint + f"/{id_ajeno}",
            "DELETE",
            token=normal,
            expected=403,
        )

        comprobar_estado(id_ajeno, True)

        print("OK usuario normal no elimina comentarios ajenos")

        # El propietario puede eliminar su propio comentario.
        call(
            endpoint + f"/{id_propio}",
            "DELETE",
            token=normal,
            expected=204,
        )

        comprobar_estado(id_propio, False)

        print("OK propietario elimina su comentario")

        # El comentario eliminado ya no aparece en las consultas.
        comentarios = call(endpoint, token=normal)

        assert id_propio not in [
            comentario["id_comentario"]
            for comentario in comentarios
        ]

        print("OK comentario eliminado oculto en consultas")

        # No se puede eliminar nuevamente.
        call(
            endpoint + f"/{id_propio}",
            "DELETE",
            token=normal,
            expected=404,
        )

        print("OK segundo intento de eliminacion rechazado")

        # El administrador puede eliminar comentarios ajenos.
        otro = call(
            endpoint,
            "POST",
            {"comentario": "Comentario para moderacion administrativa"},
            normal,
            201,
        )

        id_otro = otro["id_comentario"]

        call(
            endpoint + f"/{id_otro}",
            "DELETE",
            token=admin,
            expected=204,
        )

        comprobar_estado(id_otro, False)

        print("OK administrador modera comentarios ajenos")

        # El administrador tambien puede eliminar el comentario
        # de otro usuario que anteriormente no podia eliminar.
        call(
            endpoint + f"/{id_ajeno}",
            "DELETE",
            token=admin,
            expected=204,
        )

        comprobar_estado(id_ajeno, False)

        print("OK administrador elimina comentario de otro usuario")

        # Verificar que los tres comentarios siguen registrados
        # en MySQL, aunque esten desactivados.
        with SessionLocal() as db:
            ids = [id_propio, id_ajeno, id_otro]

            registros = db.scalars(
                select(Comentario).where(
                    Comentario.id_comentario.in_(ids)
                )
            ).all()

            assert len(registros) == 3
            assert all(comentario.estado is False for comentario in registros)

        print("OK los tres registros se conservan en MySQL")
        print("PRUEBAS DE ELIMINACION LOGICA EXITOSAS")

    finally:
        # Eliminar unicamente la publicacion temporal.
        # Sus comentarios de prueba se eliminaran en cascada.
        if ruta_blog:
            try:
                call(ruta_blog, "DELETE", token=admin)
                print("OK limpieza de publicacion temporal")
            except Exception as error:
                print(
                    "ATENCION: revisar publicacion temporal:",
                    ruta_blog,
                    error,
                )

        for token in (normal, admin):
            if token:
                try:
                    call("/auth/logout", "POST", token=token)
                except Exception:
                    print("No se pudo cerrar una sesion de prueba")


if __name__ == "__main__":
    main()
