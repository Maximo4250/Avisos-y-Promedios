# Avisos y Promedios (A&P)

Aplicación escolar para consultar horarios y avisos, organizar pendientes y seguir las notas y promedios.

## Usar la aplicación

- **Android:** [Descargar el APK de la última versión publicada](https://github.com/Maximo4250/Avisos-y-Promedios/releases/latest/download/app-release.apk).
- **Windows 10/11 de 64 bits:** [Descargar el instalador nativo](https://github.com/Maximo4250/Avisos-y-Promedios/releases/latest/download/AP-Windows-Setup.exe), independiente del navegador.
- **Navegador:** [Versión web y página común de descarga](https://maximo4250.github.io/Avisos-y-Promedios/).

En Android, abrir el APK y elegir Instalar o Actualizar. En Windows, ejecutar AP-Windows-Setup.exe: instala el programa y permite crear un acceso directo. Para actualizar Windows, ejecutar el instalador nuevo sobre la instalación anterior. La web continúa disponible como opción separada.

## Funciones

- Calendario compacto de la semana actual, desplegable a mes completo, con indicadores de actividades y fines de semana en rojo.
- Horario habitual por día y modo Pendientes semana.
- Tareas, evaluaciones y trabajos con progreso individual guardado localmente.
- Materias, notas, promedios, gráficos y datos de cursada.
- Cuenta opcional con correo y contraseña, modo invitado y preferencias de curso.
- Envío de ideas para la aplicación.
- Reparación automática de nombres de materias dañados, conservando notas e identificadores.
- Siete colores de tema disponibles en Mi cuenta.
- Delegados asignados por el administrador para cargar tareas y evaluaciones.
- Avisos individuales por curso y año, con archivado y registro de autor.

En 1.3.2 los avisos se leen exclusivamente desde `ciclos/{año}/cursos/{curso}/avisos`.
Los avisos antiguos se organizan manualmente siguiendo [la guía](AVISOS_POR_CURSO_GUIA.md).
En Días Semana las cuentas consultan su curso asignado y los invitados el seleccionado.
Los delegados publican y archivan únicamente en el curso y año de su permiso.

Los avisos y perfiles usan Firebase. Desde 1.2.2, las notas se sincronizan entre dispositivos actualizados con la misma cuenta, curso y ciclo. Los invitados y las actividades marcadas siguen guardándose localmente. No borrar datos mientras haya cambios pendientes de sincronizar. Las notificaciones push por curso están disponibles en Android; la versión web consulta los avisos dentro de la aplicación.

## Probar la sincronización

Actualizá primero el celular que contiene tus notas, iniciá sesión y esperá **Notas sincronizadas**. Si tus notas son de invitado, usá el botón de importación desde ese celular. Después abrí la web actualizada con la misma cuenta. [Pasos completos](SINCRONIZACION_GUIA.md).

## Publicar la versión preparada

1. Publicar la Release **v1.3.2** con `app-release.apk` y `AP-Windows-Setup.exe`. Ambos nombres deben mantenerse para conservar los enlaces de descarga.
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

- [Windows nativo y compilación del instalador](WINDOWS_NATIVO_GUIA.md)
- [Instalación y publicación para computadora](COMPUTADORA_GUIA.md)
- [Cuentas y cursos](FASE_2_GUIA.md)
- [Calendario y fechas](CALENDARIO_GUIA.md)
- [Asignación de delegados](DELEGADOS_GUIA.md)
- [Avisos por curso y organización manual](AVISOS_POR_CURSO_GUIA.md)
- [Reglas Firebase](configuracion_firebase/README.md)

[Versiones y novedades](https://github.com/Maximo4250/Avisos-y-Promedios/releases)
