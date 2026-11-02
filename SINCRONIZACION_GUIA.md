# Probar la sincronización de notas · A&P 1.2.2

1. Actualizá primero el celular que tiene tus notas. Instalá el APK 1.2.2 encima de la app existente, sin desinstalar ni borrar datos.
2. Abrí A&P e iniciá sesión con tu cuenta. En Mis Materias esperá **Notas sincronizadas**. Las notas existentes de esa cuenta se suben automáticamente.
3. Si tus notas están en modo invitado, entrá a Mi cuenta y usá **Importar notas del invitado** desde ese celular. No importes notas de prueba desde la computadora. La importación conserva el original y solo funciona si la cuenta local no tiene notas.
4. En la computadora cerrá todas las ventanas y pestañas de A&P y volvé a abrirla. La nueva web se activa cuando ya no quedan ventanas de la versión anterior. No borres sus datos. Si no ves el estado de sincronización en Mis Materias, aún está abierta la versión vieja: cerrala, volvé a abrir y recargá.
5. Entrá con el mismo correo, curso y ciclo. Esperá a que aparezcan las notas. Una computadora vacía no borra ni reemplaza las del teléfono.
6. Agregá una nota de prueba desde el celular y comprobá que aparece en la computadora. Borrá esa nota y comprobá el borrado en ambos.
7. Probá sin conexión: agregá una nota y cerrá la app. Al recuperar Internet y abrirla, se enviará automáticamente. Podés tocar el estado de sincronización para reintentar.

## Qué se sincroniza

Las notas y su materia, separadas por cuenta, curso y año. Los promedios se recalculan con esas notas. Las tareas marcadas como hechas siguen siendo locales en esta versión. No se avanza de ciclo automáticamente.

La actualización debe estar instalada en ambos equipos. Una versión anterior sigue guardando sus cambios solo localmente y no conoce los nuevos borrados. Actualizá todos los equipos antes de editar notas desde varios a la vez.

## Cómo se protegen los datos

SQLite se actualiza de versión 4 a 5 sin eliminar notas. Cada nota tiene ID estable y una marca de cambios pendientes. Las notas viejas equivalentes se reconocen entre dispositivos; dos notas iguales que ya existían en un mismo equipo conservan ambas ocurrencias. Dos notas nuevas iguales son independientes.

Firebase guarda documentos en `usuarios/{uid}/libretas/{ciclo}_{curso}/notas/{id}`. Cada cuenta solo accede a sus notas. No hay escritura de avisos escolares ni cambios en NEXUS. Los borrados se conservan como marcas para que una copia atrasada no restaure la nota.

La sincronización usa lecturas y escrituras del plan gratuito existente; no se habilitó Blaze. Cada nota nueva o pendiente requiere leer el documento remoto y confirmar una transacción. Las reconexiones y el historial completo también consumen lecturas, según las cuotas de Firebase.

## Publicación

El código y las reglas están en el repositorio. El APK 1.2.2 se prepara como Release en borrador. La web se actualiza con Actions → Publicar A&P para computadora → Run workflow.

Para compilar: `flutter pub get`, `flutter test`, `flutter build apk --release`; para web, usar el flujo existente. Las reglas de `configuracion_firebase/firestore.rules` deben estar publicadas antes de probar la sincronización real. La app muestra un mensaje de reglas si aún no están activas.
