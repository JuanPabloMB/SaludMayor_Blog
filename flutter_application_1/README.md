# SaludMayor Blog — Frontend

Interfaz Flutter del blog privado SaludMayor. Consume la API REST del directorio `../backend_API`.

## Desarrollo local

Con la API iniciada en `http://localhost:8000`, ejecutar desde este directorio:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-hostname localhost --web-port 8080
```

Para generar la compilación web: `flutter build web`.

El README general de instalación y entrega se preparará en la fase 4.3.
