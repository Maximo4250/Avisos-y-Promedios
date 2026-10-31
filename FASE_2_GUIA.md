# A&P — Cuentas sin Blaze

Esta guía reemplaza la propuesta anterior que usaba Python y Cloud Functions. La app ahora usa Firebase Authentication directamente y está pensada para el plan gratuito Spark. No se habilitó facturación.

## Cómo se usa

1. Abrís A&P. Podés seguir como invitado.
2. Tocás la personita de arriba a la derecha.
3. Para registrarte ponés nombre visible, correo y contraseña. El curso viene en 4to B.
4. Para ingresar usás **correo y contraseña**, no el nombre visible. El nombre puede coincidir con el de otro estudiante.
5. Si olvidás la contraseña, tocás **Olvidé mi contraseña**. Recibís un enlace por correo; revisá también Spam. No hace falta un código de recuperación propio.
6. La sesión se conserva al cerrar y abrir la app.
7. En **Mi cuenta → Mi curso** podés cambiar tu curso asignado cuando haya más cursos disponibles. Explorar otro desde el botón central no cambia tu asignación.

El correo lo administra Firebase Authentication. Las contraseñas no se guardan en la base de perfiles ni en las preferencias locales de A&P. Podés verificar tu correo desde Mi cuenta. Esta entrega no incluye cambiar el correo desde la app.

## Qué pasa con las notas

Las notas, el progreso de las tareas y el ID anterior se conservan. Los datos locales están separados por usuario, curso y ciclo lectivo.

Si ya tenías notas como invitado, podés copiarlas desde **Mi cuenta → Importar mis notas de invitado**. Se conservan los originales. Solo se permite una importación y únicamente si esa cuenta no tiene notas en el curso y año que estás viendo.

**Las notas y los checkboxes todavía no se sincronizan entre celulares.** Dos teléfonos pueden ingresar con la misma cuenta y compartir el curso asignado; las notas siguen locales. No desinstales la app esperando que la cuenta ya sea una copia de seguridad.

## Notificaciones sin servidor de pago

La app se suscribe al tema del curso:

- Invitado: último curso elegido.
- Con cuenta: curso asignado en su perfil.
- Para 4to B / 2026, el tema se llama **ap_2026_4b**.

Para enviar un aviso entrás a **Firebase → Messaging**, creás una notificación y elegís como destinatario ese tema. No elijas todos los usuarios si el mensaje es para un curso. Primero probalo con un teléfono.

**Cargar una tarea en Firestore no envía automáticamente una notificación.** Los avisos sí aparecen normalmente en la app; la notificación push se envía manualmente desde Firebase. No se agregaron recordatorios locales programados en esta adaptación.

Los temas son públicos, adecuados para avisos escolares: no son un sistema de permisos ni deben llevar datos privados. Si cambiás de curso sin conexión, la suscripción se ajusta cuando vuelve la conexión y abrís la app. Si modificás el curso de la cuenta desde otro celular, el teléfono que esté cerrado actualizará su suscripción al abrirse. Sin un servidor no se puede prometer ese cambio inmediato en todos los teléfonos apagados o cerrados.

## Estado de Firebase

Comprobado en tu consola: **Correo electrónico/contraseña ya está habilitado**.

Las reglas privadas se publicaron con tu autorización el 30/10/2026. Firebase muestra como activa la versión de hoy a las 2:37 p.m. Se conservó el acceso de NEXUS y se guardó un respaldo de la versión anterior. No se cambió la facturación ni se activó Blaze.

Las reglas publicadas conservan NEXUS y los demás namespaces ajenos a A&P como estaban, y protegen específicamente los perfiles nuevos. No se modificaron datos, tareas ni evaluaciones en la nube. GitHub y el enlace de descarga siguen con la versión anterior.

## Qué cambió y qué costó resolver

- Se retiraron Python, Cloud Functions y App Check de esta función. Ya no hay un backend de pago configurado para desplegar desde el proyecto.
- Firebase resuelve el inicio de sesión y el correo de recuperación. Por eso el correo pasó a ser obligatorio.
- La cuenta puede crearse aunque falle luego la conexión para guardar su perfil: la app avisa y permite reintentarlo, sin pedir que vuelvas a registrarte.
- Cerrar sesión funciona sin contactar a un servidor propio y restaura el ámbito del invitado.
- Se conservó la navegación y se distinguió el curso que mirás del curso al que pertenecés.
- Hubo que integrar las reglas con NEXUS para no reemplazar la configuración de la otra app.

## Comprobaciones

- 31 pruebas de Flutter aprobadas, incluyendo acceso, recuperación, datos separados, navegación y suscripciones por curso.
- 14 pruebas contra Firestore Emulator aprobadas, incluyendo perfiles privados y compatibilidad con NEXUS.
- 2 pruebas de migración SQLite aprobadas: conservación de notas, tareas e ID, y separación por cuenta/curso/año.
- `flutter analyze`: sin problemas.
- Compilación Android debug: correcta.

Las pruebas de cuentas usan un repositorio simulado; las de reglas usan el emulador real de Firestore. Falta probar registro, correos y notificaciones desde un teléfono real antes de distribuir la nueva versión.

## Límites del plan gratuito

Spark tiene cuotas: si se alcanzan, algunos servicios pueden limitarse temporalmente. Mantener el proyecto en Spark evita habilitar cobros por uso; no significa capacidad ilimitada. Como el proyecto también aloja NEXUS, ambas apps comparten cuotas. [Planes de Firebase](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans) y [límites de Authentication](https://firebase.google.com/docs/auth/limits).

Referencias: [correo y contraseña en Flutter](https://firebase.google.com/docs/auth/flutter/password-auth), [notificaciones por temas](https://firebase.google.com/docs/cloud-messaging/manage-topic-subscriptions), [ejemplo oficial de envío desde consola](https://github.com/firebase/quickstart-android/blob/master/messaging/README.md).
