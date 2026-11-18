# SaludMayor Blog — Fase 3.9

## Objetivo

Implementar el CRUD de publicaciones en Flutter utilizando los endpoints ya existentes de FastAPI. Solo se muestra la administración en la interfaz del administrador; la API mantiene la validación real de permisos.

## Archivos

Reemplazar los archivos existentes:

- `lib/core/api_client.dart`
- `lib/services/blog_service.dart`
- `lib/screens/publications_page.dart`
- `lib/screens/role_home_page.dart`

Crear:

- `lib/screens/post_editor_page.dart`

## Dependencia

Desde `flutter_application_1` ejecutar:

```powershell
flutter pub add http_parser
```

`image_picker` ya forma parte de las dependencias del proyecto base.

## Endpoints utilizados

- `POST /blog` — crear publicación.
- `PATCH /blog/{id_blog}` — editar publicación.
- `DELETE /blog/{id_blog}` — eliminar publicación.
- `PUT /blog/{id_blog}/imagen` — subir o reemplazar imagen.
- `DELETE /blog/{id_blog}/imagen` — quitar imagen.
- `GET /blog/{id_blog}` — recuperar el detalle para editar.
- `GET /categorias` — consultar categorías activas.

El backend valida que crear, editar, eliminar y administrar imágenes requiere rol `administrador`. Las imágenes se envían como `multipart/form-data` usando el campo `archivo`; FastAPI valida formato, MIME y tamaño máximo de 5 MB antes de guardarlas en MySQL.

## Instalación

Copiar el contenido de `lib/` en la carpeta `flutter_application_1/lib/`, respetando las rutas. No reemplazar toda la carpeta `lib`; solo los archivos enumerados.

Después ejecutar:

```powershell
dart format lib/core/api_client.dart lib/services/blog_service.dart lib/screens/publications_page.dart lib/screens/role_home_page.dart lib/screens/post_editor_page.dart
flutter pub get
flutter analyze
flutter test
flutter build web
```

## Flujo de uso

1. Iniciar FastAPI.
2. Iniciar Flutter en Chrome.
3. Entrar con una cuenta administradora.
4. Abrir Publicaciones y crear, editar o eliminar una publicación.
5. Entrar con un usuario normal y comprobar que no aparecen controles administrativos.

No se debe considerar terminada la fase hasta probar el flujo con ambos roles y verificar la persistencia en MySQL.

## Pruebas de la fase

Se incluye `test/blog_crud_service_test.dart`, con pruebas de los métodos POST, PATCH y DELETE del servicio de publicaciones.
