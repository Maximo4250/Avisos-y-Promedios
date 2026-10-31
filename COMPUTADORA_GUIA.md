# A&P en celular y computadora

La versión de computadora es una aplicación web instalable (PWA): se abre en Chrome o Edge y se instala con su propio icono y ventana. No necesita un emulador de Android ni un instalador EXE. La primera apertura requiere Internet.

## Un mismo enlace

Al publicar la carpeta preparada con GitHub Pages, el enlace común será:

https://maximo4250.github.io/Avisos-y-Promedios/

Es la dirección prevista; no se ha activado ni publicado desde este trabajo.

La página ofrece dos botones:

- Android: descarga `app-release.apk` de la última versión de GitHub.
- Computadora: abre A&P y permite instalarla desde Chrome o Edge. También se puede usar sin instalar.

Un enlace que termina en `.apk` siempre descarga Android. Para compartir ambas opciones hay que compartir la página común.

## Lo que se conserva

Horarios, calendario, materias, promedios, pendientes, ideas, modo invitado y cuentas. Usa el Firebase existente y los mismos avisos. No se duplicó la base compartida ni se activó facturación.

Las notas y los estados de tareas se guardan en el navegador y permanecen al cerrar y abrir. Instalar desde ese mismo navegador conserva esos datos. Otro navegador, perfil o dispositivo tiene su almacenamiento separado. Borrar los datos del sitio o usar incógnito puede perder esas notas. Todavía no hay sincronización de notas entre equipos.

Las notificaciones push por curso continúan en Android. En computadora se consultan los avisos dentro de A&P: no se configuró push web. El conteo remoto de instalaciones actual sigue contando Android; no se etiquetan computadoras como si fueran teléfonos.

La copia instalada guarda los recursos de la aplicación para posteriores aperturas sin conexión. Los avisos nuevos y las operaciones de cuenta necesitan Internet. Al publicarse una actualización, cerrar todas las ventanas de A&P permite que se active la nueva versión.

## Publicación cuando se suba el proyecto

1. Subir el proyecto Flutter al repositorio `Maximo4250/Avisos-y-Promedios`, sin carpetas de compilación, respaldos ni credenciales privadas. Mantener `pubspec.lock` y los archivos de `web/`.
2. En GitHub: **Settings → Pages → Source → GitHub Actions**.
3. En **Actions**, ejecutar **Publicar A&P para computadora → Run workflow**. El flujo compila y publica la página común y la app web. No requiere claves de servicio de Firebase.
4. Publicar el APK Android nuevo en una Release y nombrar el archivo exactamente `app-release.apk`. El botón Android usa `releases/latest/download/app-release.apk` para apuntar siempre a la última Release estable.
5. Probar ambos botones desde la dirección común. No usar el enlace antiguo que apunta a una versión fija si se quiere ofrecer siempre la última.

El acceso con correo y contraseña usa la nueva app web de A&P registrada en el proyecto Firebase existente. Si más adelante se añaden proveedores como Google, habrá que autorizar el dominio de GitHub Pages en Authentication antes de habilitarlos.

## Compilar localmente

Desde la carpeta del proyecto:

```powershell
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter build web --release --base-href /Avisos-y-Promedios/app/ --pwa-strategy=none --no-web-resources-cdn
python tool/preparar_web.py
```

La carpeta `build/publicacion_web` es el sitio preparado. Debe servirse mediante HTTP para probarlo, o HTTPS para instalarlo públicamente; abrir su HTML con doble clic no ejecuta la aplicación correctamente.

Se eligió web instalable porque Firebase advierte que su soporte nativo de Windows está orientado al desarrollo, y esta PC no tiene Visual Studio con las herramientas de C++ necesarias para compilar una app nativa de Windows. El almacenamiento web reutiliza el esquema SQLite existente a través de IndexedDB; la biblioteca adaptadora se declara experimental y debe seguir probándose antes de distribuir masivamente.

Fuentes oficiales: https://firebase.google.com/docs/flutter/setup y https://pub.dev/packages/sqflite_common_ffi_web
