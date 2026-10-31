# Avisos y Promedios (A&P)

Aplicación escolar para consultar horarios y avisos, organizar pendientes y seguir las notas y promedios.

## Usar la aplicación

- **Android:** [Descargar el APK de la última versión publicada](https://github.com/Maximo4250/Avisos-y-Promedios/releases/latest/download/app-release.apk).
- **Computadora:** versión web instalable desde Chrome o Edge. La página común estará en [A&P para celular y computadora](https://maximo4250.github.io/Avisos-y-Promedios/) después de activar GitHub Pages y ejecutar el flujo de publicación.

En Android, abrir el APK descargado y elegir Instalar o Actualizar. En computadora, abrir la versión web y elegir **Instalar A&P** desde la aplicación o el menú del navegador. Un APK se instala en Android; la computadora utiliza la aplicación web.

## Funciones

- Calendario mensual con indicadores de actividades, día y semana actuales.
- Horario habitual por día y modo Pendientes semana.
- Tareas, evaluaciones y trabajos con progreso individual guardado localmente.
- Materias, notas, promedios, gráficos y datos de cursada.
- Cuenta opcional con correo y contraseña, modo invitado y preferencias de curso.
- Envío de ideas para la aplicación.

Los avisos y perfiles usan Firebase. Las notas y las actividades marcadas se guardan en cada dispositivo o navegador: todavía no se sincronizan entre equipos. No borrar los datos del sitio si se quieren conservar las notas de computadora. Las notificaciones push por curso están disponibles en Android; la versión web consulta los avisos dentro de la aplicación.

## Publicar la versión preparada

1. Revisar la Release **v1.2.1** en borrador y publicar cuando corresponda. Mantener el nombre del archivo Android como `app-release.apk`.
2. En **Settings → Pages**, seleccionar **GitHub Actions** como origen.
3. En **Actions**, ejecutar **Publicar A&P para computadora → Run workflow**.
4. Compartir la dirección común: `https://maximo4250.github.io/Avisos-y-Promedios/`.

El código no publica automáticamente una Release ni activa la web con cada cambio. La publicación web se ejecuta manualmente.

## Desarrollo

Proyecto Flutter. La versión usada para validación es **Flutter 3.41.7**. Instalar las dependencias con `flutter pub get`.

```sh
flutter analyze
flutter test
dart run sqflite_common_ffi_web:setup
flutter build web --release --base-href /Avisos-y-Promedios/app/ --pwa-strategy=none --no-web-resources-cdn
python tool/preparar_web.py
```

La salida web queda en `build/publicacion_web`. La primera apertura requiere Internet y la instalación pública requiere HTTPS.

Para Android: `flutter build apk --release`. El esquema de firma existente se conserva; la clave local no se publica en este repositorio. Una compilación en otra máquina necesita el certificado original para actualizar instalaciones existentes.

La configuración de cliente Firebase incluida identifica el proyecto y no es una clave administrativa. Las reglas controlan el acceso a los datos. No se deben subir claves privadas, credenciales de servicio ni almacenes de firma.

## Guías

- [Instalación y publicación para computadora](COMPUTADORA_GUIA.md)
- [Cuentas y cursos](FASE_2_GUIA.md)
- [Calendario y fechas](CALENDARIO_GUIA.md)
- [Reglas Firebase](configuracion_firebase/README.md)

[Versiones y novedades](https://github.com/Maximo4250/Avisos-y-Promedios/releases)
