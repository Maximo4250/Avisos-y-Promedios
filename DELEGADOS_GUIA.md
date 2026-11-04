# Delegados en A&P

Desde A&P 1.2.3 los delegados publican y archivan avisos individuales de su curso y año. Las reglas correspondientes ya se publicaron en Firebase; los cargos los asigna exclusivamente el administrador.

## Elegir a un delegado

1. El estudiante debe crear una cuenta de A&P con correo y contraseña.
2. En Firebase → Authentication → Usuarios, buscá su correo y copiá su **UID**.
3. En Firestore, abrí `usuarios` y el documento cuyo nombre es ese UID.
4. Dentro de ese documento, pulsá **Iniciar colección**. Nombre de la colección: `permisos`.
5. ID del documento: `delegado`.
6. Agregá estos campos:

| Campo | Tipo en Firebase | Valor para 4to B |
|---|---|---|
| activo | boolean | true |
| curso | string | 4b |
| ciclo | int64 / integer | 2026 |

La ruta final es `usuarios/UID/permisos/delegado`. No agregues un campo `rol` en el perfil principal ni modifiques sus campos actuales.

Sin ese documento, o con `activo: false`, la cuenta es estudiante. Para quitar el cargo cambiá **activo** a **false**. Las reglas bloquean las nuevas publicaciones aunque el teléfono aún muestre un permiso antiguo. El indicador visual se actualiza al recibir la información de Firebase.

El permiso es para un curso y ciclo concretos. Cambiar el curso predeterminado de la cuenta no cambia la delegación. Para otros cursos, primero habilitá su catálogo y horario; después asigná el código de curso correspondiente en este documento.

## Qué verá el delegado

- Insignia de delegado junto al acceso a cuenta en las pantallas de A&P.
- En **Mi cuenta**, etiqueta **Delegado · 4to B** y botón **Cargar tarea o evaluación**.
- Formulario: día (lunes a viernes), materia de ese día, tipo (tarea o evaluación), descripción y fecha. Fecha opcional en tareas y obligatoria en evaluaciones.
- Botón **Publicar para el curso**, seguido de la confirmación y la opción de cargar otro aviso.

Necesita Internet para confirmar la publicación. Si se interrumpe, puede reintentar: el mismo intento conserva su identificador para evitar duplicados. El formulario mantiene lo escrito si falla. El calendario permite elegir fechas que coincidan con el día seleccionado.

Los estudiantes ven los avisos en horario, calendario, pendientes e historia por materia. Cada aviso ocupa un documento independiente en `ciclos/{año}/cursos/{curso}/avisos`.

En Mi cuenta, «Gestionar avisos del curso» permite archivar cualquier aviso del curso y año autorizado, incluso de otro delegado. Pide confirmación, conserva contenido y registra archivado_por y archivado_en. Los delegados no borran físicamente ni restauran avisos.

No existe un botón de traslado para delegados. Los avisos antiguos se organizan manualmente según [la guía por curso](AVISOS_POR_CURSO_GUIA.md). El administrador puede revisar o recuperar los archivados desde Firebase Console.

No obtienen acceso a las notas privadas de otros estudiantes, a los cargos de otras personas ni a datos de NEXUS. Tampoco pueden nombrarse delegados ni nombrar a otros.

## Mandar recordatorios solo al grupo de delegados

En Firebase → Messaging, creá una notificación. En el destino, elegí **Tema / Topic** y escribí uno de estos nombres:

| Destinatarios | Tema |
|---|---|
| Todos los delegados | `ap_delegados` |
| Delegados de 4to B, ciclo 2026 | `ap_delegados_2026_4b` |

Ejemplo: título **Recordatorio para delegados**; mensaje **Recuerden cargar las tareas y evaluaciones del curso de hoy**.

El tema se registra cuando un delegado abre A&P en Android con la nueva versión. Si aún no aparece en las sugerencias de Firebase, primero debe abrir la app un delegado válido. Esto no añade una etiqueta administrativa de Analytics: son temas de FCM con esos nombres exactos.

Las notificaciones push están disponibles en Android. La web puede mostrar el cargo y cargar avisos, pero todavía no recibe push. Cargar un aviso no envía automáticamente una notificación a los estudiantes: los envíos siguen siendo manuales desde Messaging.

Los temas de FCM sirven para recordatorios generales, no como canal privado: un cliente externo puede suscribirse si conoce el nombre. Quitar el cargo o cerrar sesión hace que la app deje esos temas cuando está abierta o vuelve a abrirse; un teléfono cerrado no se puede desuscribir inmediatamente con esta configuración gratuita sin backend. El permiso de publicación es independiente y Firebase sí lo comprueba en cada escritura.

## Distribución

Actualizar la app de delegados y estudiantes antes de retirar los avisos antiguos. Las reglas preservan notas y NEXUS, no requieren Blaze ni servidor Python. El código y los paquetes de una versión deben revisarse antes de publicarlos.

Referencias oficiales: [reglas por roles](https://firebase.google.com/docs/firestore/solutions/role-based-access), [temas de notificaciones](https://firebase.google.com/docs/cloud-messaging/manage-topic-subscriptions).
