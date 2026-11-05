# A&P 1.3.2 en Android, Windows y navegador

## Un mismo enlace para compartir

https://maximo4250.github.io/Avisos-y-Promedios/

La página ofrece tres opciones:

- Android: descarga app-release.apk de la última versión publicada.
- Windows: descarga AP-Windows-Setup.exe. Programa nativo para Windows 10/11 de 64 bits, sin navegador ni herramientas de desarrollo.
- Navegador: abre la app web, que sigue disponible por separado.

## Instalar y actualizar

Android: ejecutar el APK nuevo sobre la instalación existente, sin desinstalar.

Windows: ejecutar el instalador nuevo sobre el anterior. Instala para el usuario actual, permite crear un acceso directo y conserva las notas en LocalAppData/Avisos y Promedios/datos. El aviso de actualizaciones Android no descarga APK en Windows. Las actualizaciones nativas se instalan con el instalador nuevo. Más detalles: [guía Windows](WINDOWS_NATIVO_GUIA.md).

Web: cerrar las ventanas de A&P y volver a abrir la dirección pública para activar los recursos nuevos. La dirección 127.0.0.1 es solo para pruebas locales: no es la página pública.

## Cuenta y datos

Las cuentas, materias, notas sincronizadas y avisos usan el mismo Firebase, curso y año. Esperar «Notas sincronizadas» en el dispositivo que tiene las notas antes de abrir otra instalación. Los datos de invitado y los pendientes marcados son locales y no se trasladan automáticamente del navegador a Windows.

Las notificaciones push y el conteo remoto de instalaciones continúan disponibles en Android. Windows no se registra como si fuera un teléfono. No se duplican bases compartidas ni se activa facturación.

## Publicar

1. Guardar las fuentes en el repositorio, sin bases de datos, respaldos ni credenciales privadas.
2. Publicar una Release estable con los nombres exactos app-release.apk y AP-Windows-Setup.exe. El ZIP portátil es opcional.
3. Ejecutar Actions → Publicar A&P para computadora. El flujo compila la web y publica la página común.
4. En Firebase Remote Config, actualizar latest_version a la versión Android publicada. Mantener download_url en https://github.com/Maximo4250/Avisos-y-Promedios/releases/latest/download/app-release.apk . Publicar los cambios.
5. Probar las tres opciones desde la página común.

La configuración de cliente Firebase no es una credencial administrativa; las reglas siguen protegiendo los datos. No se necesitan claves de servicio para GitHub Pages.

## Validación y límites

La compilación nativa Windows 1.3.2+9 fue verificada en la computadora de desarrollo y el usuario confirmó el funcionamiento en otras tres PC. Corrige la incompatibilidad BMI2 de la biblioteca Snappy del SDK. Firebase aún documenta Windows como soporte experimental para desarrollo: https://firebase.google.com/docs/flutter/setup . Las pruebas no garantizan todos los equipos; la web sigue como alternativa.

Para compilar la web:

```
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter build web --release --base-href /Avisos-y-Promedios/app/ --pwa-strategy=none --no-web-resources-cdn
python tool/preparar_web.py
```

Para compilar Windows y su instalador, consultar WINDOWS_NATIVO_GUIA.md.
