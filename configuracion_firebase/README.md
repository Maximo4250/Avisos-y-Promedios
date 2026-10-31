# A&P — Configuración de cuentas con Spark

Esta configuración reemplaza el backend Python anterior. No requiere Blaze, Cloud Functions, SMTP, extensiones Trigger Email, claves de servicio ni tokens personalizados. El backend anterior está archivado fuera del proyecto activo.

## Estado y despliegue

Proyecto existente: `evaluacionescolegio-5b5e2`. Correo/Contraseña está habilitado, comprobado en la consola. Reglas: `configuracion_firebase/firestore.rules`. Publicadas con autorización explícita del usuario el 30/10/2026; la consola confirma activa la versión de hoy a las 2:37 p.m. Se conservó NEXUS y los namespaces ajenos a A&P como estaban, y se guardó respaldo de las reglas anteriores. La publicación inicialmente detenida por revisión automática se completó después de recibir autorización; no se utilizaron vías alternativas para eludirla.

No habilitar Blaze, no actualizar a Identity Platform como parte de esta entrega y no asociar una cuenta de facturación. Conservar los límites de Spark. El consumo de NEXUS y A&P comparte el mismo proyecto.

Las reglas ya están publicadas. Probar el APK de desarrollo en un teléfono. Firebase Authentication envía directamente la recuperación; revisar sus plantillas y el correo de Spam. La app solicita al menos 10 caracteres para el registro. Para imponerlo también a clientes externos, configurar la política de contraseña de Authentication sin cambiar proveedores ni habilitar servicios de pago.

## Datos

`usuarios/{uid}` contiene exclusivamente `usuario` (nombre visible), `curso_predeterminado`, `ciclo`, `creada_en` y `actualizada_en`. No contiene correo, contraseñas, hashes, roles ni claves de recuperación. El correo se consulta desde Firebase Auth; el perfil local incluye una copia de correo para mostrar información offline.

Las reglas permiten que un usuario autenticado por contraseña lea su propio documento y cree el perfil inicial. Las modificaciones se limitan a curso y fecha de actualización; se valida que el curso esté disponible. Se rechazan lecturas de perfiles ajenos, listados, campos de administrador, contraseñas, cambios de ciclo y borrados. NEXUS conserva sus reglas; el wildcard heredado excluye los namespaces protegidos para no saltarse las reglas nuevas. Los namespaces ajenos siguen con su comportamiento previo; no se hizo una auditoría ni un endurecimiento general de otras apps.

4to B / 2026 continúa en `avisos_semana/{dia}`, campo `evalucaciones`. No se duplican ni migran sus avisos. Los futuros cursos usan `ciclos/2026/cursos/{id}` con `nombre`, `disponible`, `materias` y `horario`. Materias: lista de mapas con `nombre` y `es_doble`. Horario: lista de mapas con `codigo`, `nombre`, `salida`, `clases`; cada clase contiene `hora` y `materia`. Los avisos se ubican debajo de cada curso en `avisos_semana/{dia}`. No habilitar un curso sin esos datos.

El ciclo sigue siendo 2026 y no avanza automáticamente por el reloj. El cambio de año, historial, delegación de carga y respaldo de notas no forman parte de esta adaptación.

## Mensajería

FCM por temas `ap_{ciclo}_{curso}`, por ejemplo `ap_2026_4b`. En Messaging, enviar a ese tema, no al público general. Nunca incorporar claves FCM/Admin al APK. No hay trigger de Firestore: el envío push es manual.

Los temas no son autorizaciones ni grupos privados. Las suscripciones se guardan por dispositivo; se retira el tema anterior antes de agregar otro. Si falla la conexión, la operación queda pendiente para reintentar al abrir o reanudar la app. El perfil de cuenta se observa en tiempo real cuando la app está activa, y se vuelve a consultar al reanudar. Si otro teléfono permanece cerrado, puede conservar el tema anterior hasta abrirse. No se promete revocación inmediata de notificaciones en dispositivos offline.

## Pruebas

```powershell
flutter pub get
flutter analyze
flutter test
python -m unittest discover -s pruebas_locales -v
flutter build apk --debug
```

Las pruebas de `pruebas_reglas` requieren Firestore Emulator local en `127.0.0.1:8787` y proyecto ficticio `demo-ap-spark`, cargando el archivo de reglas del proyecto. El test usa solicitudes REST únicamente contra localhost:

```powershell
python -m unittest discover -s pruebas_reglas -v
```

En esta sesión se usó el emulador oficial 1.22.0, descargado de Google y verificado con el SHA-256 publicado por Firebase Tools. Las pruebas no escriben en producción. El cliente Flutter no se conecta automáticamente a emuladores. No usar el proyecto real para los tests REST.

Validar en teléfonos reales: registro, persistencia al reabrir, login, recuperación, perfil pendiente y reintento, cierre de sesión offline, importación única del invitado y envío manual al tema correcto. Dos teléfonos comparten identidad/curso, pero todavía no notas ni checkboxes.

El APK debug se generó para desarrollo. Antes de distribuir, aumentar versión/compilación, generar release con el certificado compatible con las instalaciones anteriores, probarlo y recién después publicar en GitHub y actualizar Remote Config. La configuración de firma existente usa debug para release; no cambiarla sin planificar la actualización. No se publicó un APK nuevo.

Referencias oficiales: https://firebase.google.com/docs/auth/flutter/password-auth ; https://firebase.google.com/docs/auth/limits ; https://firebase.google.com/docs/projects/billing/firebase-pricing-plans ; https://firebase.google.com/docs/cloud-messaging/manage-topic-subscriptions .
