# Calendario de Días Semana

Se agregó un calendario mensual dentro de la pestaña existente. El horario habitual y su selector de días siguen debajo.

- Día actual: fondo dorado.
- Semana actual: franja y borde dorados suaves, de lunes a domingo.
- Fecha seleccionada: borde blanco cuando no es hoy.
- Punto: hay al menos una actividad con fecha ese día. Los avisos se consultan debajo, en el horario del día seleccionado.
- Flechas: cambiar de mes. Botón de calendario: volver a hoy.

## Dónde cargar la fecha

Para 4to B actual, abrir **Firestore → avisos_semana → documento del día → evalucaciones → mapa del aviso**. Dentro de ese mismo mapa, agregar o completar el campo **fecha**, de tipo **string**, usando año-mes-día:

```text
materia: "Matemática"
tipo: "tarea"
detalle: "Resolver los ejercicios"
fecha: "2026-11-12"
```

Sirve para los tipos `tarea`, `evaluacion` y `trabajo`. También se reconoce `trabajo práctico`, `trabajo practico` y `TP` como trabajo. A diferencia de la versión anterior, las tareas y los trabajos ahora también conservan una fecha explícita para el calendario y la planificación.

No crear otra colección ni duplicar el aviso. El calendario usa la colección que ya existe para el curso activo. La fecha completa manda sobre el día del documento para ubicar el punto; no se deduce una fecha a partir de “Lunes” o “Jueves”.

## Si el aviso no tiene fecha

Sigue apareciendo en el horario habitual del día donde fue publicado. Se quitó el resumen intermedio y la sección «Sin fecha» de esta pantalla. No recibe un punto en una fecha concreta: el calendario no inventa cuándo se entrega.

Los avisos de fechas anteriores siguen visibles en el calendario mientras se conserven en Firestore. Esto no crea un archivo histórico de avisos que el administrador haya eliminado.

## Datos y consumo

El calendario, los botones del horario y las clases reutilizan una misma suscripción de avisos en esta pantalla. No se hace una consulta por celda ni por mes, ni se escribe en Firebase al navegar. La vista Pendientes mantiene su funcionamiento y los trabajos se pueden completar como tareas.

No se modificaron datos ni reglas de Firebase y no se publicó una actualización en GitHub como parte de este cambio. La imagen de vista previa usa actividades de ejemplo; no son tareas cargadas en tu base real.
