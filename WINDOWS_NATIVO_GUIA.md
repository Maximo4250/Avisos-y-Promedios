# A&P nativa para Windows (versión 1.3.2)

Esta aplicación ejecuta Flutter directamente en Windows; no abre Chrome, Edge ni un servidor local. La web continúa siendo una opción separada.

## Instalar y usar

- Instalador: AP-Windows-Setup.exe. Instalación para el usuario actual, sin permisos de administrador.
- Alternativa portátil: extraer AP-Windows-Portable.zip completo y abrir AvisosYPromedios.exe. No copiar solamente el ejecutable: las bibliotecas y la carpeta data son necesarias.
- Las notas se guardan en `%LOCALAPPDATA%\Avisos y Promedios\datos\notas_app.db`, fuera de la instalación. Actualizar o desinstalar el programa no elimina esa carpeta.
- La cuenta y las notas sincronizadas usan el mismo proyecto Firebase, curso y año de Android. Esperar «Notas sincronizadas» en el dispositivo de origen antes de entrar en Windows.
- Las notas y pendientes que solo existen como invitado en el navegador no se trasladan automáticamente a Windows. Conservar esa instalación hasta recuperar lo necesario.
- El inicio de sesión de Windows es independiente del del navegador. Nunca se extraen contraseñas ni sesiones del navegador.
- Las notificaciones push y el aviso de actualización de APK permanecen solo en Android. Windows se actualiza instalando el instalador nuevo sobre el anterior.

## Estado de compatibilidad

Firebase Auth y Firestore para Windows están marcados como experimentales para desarrollo por Firebase: https://firebase.google.com/docs/flutter/setup . La compilación 1.3.2+9 fue verificada en la PC de desarrollo y el usuario confirmó su funcionamiento en otras tres computadoras. Esta validación no elimina el carácter experimental del SDK de Firebase. La versión web sigue disponible como alternativa.

## Compilar

Flutter 3.41.7 y Visual Studio con desarrollo de escritorio en C++ y SDK de Windows. No confundir Visual Studio con VS Code.

```
flutter pub get
flutter build windows --release
powershell -File tool/preparar_windows.ps1 -Iscc "C:\ruta\ISCC.exe"
```

Inno Setup compila `windows/instalador/ap.iss`. Conserva el AppId del instalador y la ruta de datos entre versiones. La descarga para Windows debe publicarse con nombre AP-Windows-Setup.exe, separado de app-release.apk.

## Corrección de compatibilidad (compilación 9)

Se recompila Snappy 1.1.9 con el mismo espacio de nombres del SDK, sin BMI2 ni SSSE3. Corrige el cierre 0xc000001d en AMD FX. La ventana también se muestra antes del primer frame para evitar que quede oculta. El instalador actualiza la instalación anterior con el mismo AppId; conserva las notas.
