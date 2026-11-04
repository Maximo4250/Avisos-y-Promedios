# Organización manual de avisos por curso

Actualizado el 3 de noviembre de 2026. Esta guía reemplaza las instrucciones anteriores de «Organizar avisos anteriores». Ese botón y el traslado automático se quitaron de la app y se bloqueó el traslado para delegados en las reglas publicadas.

## Ubicación única de los avisos

ciclos / 2026 / cursos / 4b / avisos / ID_DEL_AVISO

En Firebase, lo que llamamos carpeta es un documento con una subcolección. Usá exactamente `4b` en minúsculas. `4B` sería otra ubicación y la app no la leería. El nombre visible puede ser «4to B».

Los avisos nuevos de un delegado autorizado para curso=4b y ciclo=2026 se guardan automáticamente en esa ruta, uno por documento. No hay que volver a indicar el curso en cada tarea. Los permisos impiden publicar o archivar en otro curso o año.

Días Semana usa el curso predeterminado y el año de la cuenta conectada. Si se explora otro curso desde el selector, Días conserva el de la cuenta. Para cambiar el asignado, se usa la configuración de cuenta. Los invitados usan el curso que seleccionaron. La lista del horario también usa el curso de la cuenta, para no mezclar un horario con avisos de otro curso.

## Crear las carpetas una sola vez

1. En Cloud Firestore → Datos, abrí la colección `ciclos`. Si no existe, pulsá Iniciar colección y escribí `ciclos`.
2. Abrí o creá el documento `2026`. Si necesitás un campo para guardarlo, usá `nombre` (string): `Ciclo 2026`.
3. Dentro, abrí o creá la colección `cursos` y el documento `4b`.
4. En `4b`, podés usar `nombre` (string): `4to B`, y `disponible` (boolean): `true`. Si el documento ya existe, conservá sus campos y subcolecciones.
5. Dentro del documento `4b`, abrí o creá la subcolección `avisos`.

La primera tarea creada desde la app también crea automáticamente la subcolección `avisos`, incluso si los documentos padres aún no tenían campos.

## Copiar los avisos anteriores, uno por uno

1. Abrí `avisos_semana` y revisá cada documento: `Lu`, `Ma`, `Mi`, `Ju`, `Vi`, y también los que empiezan con `delegado_`.
2. Dentro de `evalucaciones`, cada elemento del array (0, 1, etc.) es un aviso distinto. No copies toda la lista como un solo aviso.
3. Para el elemento 0 de `Ju`, usá en la nueva subcolección el ID `legado_Ju_0`; para el elemento 1, `legado_Ju_1`. La regla general es `legado_NOMBREDELORIGINAL_INDICE`. Si el documento ya existe en la nueva ruta, revisalo: no lo dupliques ni sobrescribas su estado archivado.
4. Creá el documento con los campos de la tabla siguiente. En `datos`, elegí tipo **map**, no array, e ingresá los campos del elemento original, respetando sus valores.
5. Abrí la app actualizada y comprobá materia, descripción, día y fecha. Repetí con el resto.

| Campo del documento | Tipo en Firebase | Valor para un aviso de Ju de 4to B |
|---|---|---|
| `curso` | string | `4b` |
| `ciclo` | int64 / integer | `2026` |
| `dia` | string | `Ju` |
| `archivado` | boolean | `false`, solo si es una copia nueva activa |
| `autor_uid` | string | Copiar el autor original si existe; si no, `administrador` |
| `creada_en` | timestamp | Copiar la original si existe; si no, la fecha en que creás el registro |
| `datos` | map | Campos del aviso original: ver abajo |
| `origen_documento` | string | `Ju` (opcional, para saber de dónde vino) |
| `origen_indice` | int64 / integer | `0` (opcional) |

Dentro del mapa `datos`:

| Campo | Tipo | Qué copiar |
|---|---|---|
| `materia` | string | El nombre exacto del original, por ejemplo `Matemática` |
| `tipo` | string | El tipo del original; los nuevos se cargan como `tarea` o `evaluacion` |
| `detalle` | string | La descripción completa original |
| `fecha` | string | Si existe, conservarla, por ejemplo `2026-11-12`. Si no existe, no inventarla |
| `id` | string | Solo si el original ya lo tiene: conservarlo exactamente |

No inventes un `id` dentro de `datos` para un aviso antiguo que no lo tenía. La app usa su contenido y día para reconocer el progreso ya guardado; cambiar esa identidad puede hacer que aparezca como pendiente otra vez. El ID externo del documento (`legado_Ju_0`) sí es necesario.

El código del día es `Lu`, `Ma`, `Mi`, `Ju` o `Vi`. Si el documento antiguo tiene su propio campo `dia`, copiá ese campo: no uses el nombre `delegado_...` como día. Si ya había una fecha, conservarla evita alterar el calendario.

Los documentos en la nueva ubicación pueden estar archivados (`archivado: true`). Eso significa que el traslado anterior ya había creado esa copia; no la vuelvas a crear ni la pongas en false por accidente.

## Qué ocurre con los antiguos

La app actualizada solo lee `ciclos/{año}/cursos/{curso}/avisos`. No consulta `avisos_semana`. Por eso lo que todavía esté únicamente en la colección antigua dejará de mostrarse hasta que lo copies manualmente. No se eliminó ningún aviso real con este cambio.

Antes de retirar los originales, conservá un respaldo y verificá todas las copias y las versiones de la app que usan los alumnos. Las versiones antiguas siguen consultando la colección anterior. Borrar el original es una operación separada: no hace falta para que la app nueva lea los avisos organizados.

## Archivados y recuperación

Están en la misma subcolección `avisos` con `archivado: true`, `archivado_por` y `archivado_en`. No se muestran en Días ni Pendientes. Como administrador, podés recuperarlos cambiando `archivado` a false desde Firebase. Los delegados no pueden restaurar ni borrar físicamente.

## Estado de entrega

Cambios de app guardados en el proyecto local; todavía no se subieron a GitHub ni se compiló un APK nuevo de esta modificación. Reiniciá la ejecución desde VS Code para probarlos. La restricción de traslado sí quedó publicada en Firebase.

Comprobación: 63 pruebas Flutter y 46 pruebas de permisos aprobadas; análisis sin incidencias.
