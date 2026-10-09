# Registro crítico de IA — Módulo 5 (dominio e integración)
## Entregable 10

**Herramienta:** Claude Code (Anthropic), usada para redactar los borradores
de `docs/dominio/` y `docs/integracion/` y para verificar el contrato contra
la aplicación en ejecución.

El trabajo delegado del spike 1 tiene su propia auditoría en
`experimentos/05-auditoria-ia-s9.md` (EDAV 2). Este registro cubre solo los
documentos del módulo 5 que no forman parte del spike.

La columna **Decisión del equipo** registra qué se aceptó, qué se rechazó y
por qué. Una propuesta no forma parte del dossier hasta que el equipo decide.

---

## 1. Propuestas de la IA y decisión del equipo

| # | Propuesta de la IA | Dónde | Decisión del equipo | Razón |
|---|---|---|---|---|
| IA-1 | Cinco contextos: Adopciones (núcleo), Mascotas y Veterinarias (soporte), Identidad y Notificaciones (genéricos) | `docs/dominio/subdominios.md` | Aceptado → **Reemplazado por IA-10** (2026-10-09) | Se aceptó porque coincidía con los módulos de dossier/15 y ADR-03; la revisión del tutor mostró que esa justificación es circular (§4) |
| IA-2 | No crear contextos para "Etapas de adopción", "Búsqueda geoespacial" ni "Fundaciones" | `docs/dominio/subdominios.md` §3 | Aceptado | Separarlos rompería TRX-02 o no aportaría conceptos propios |
| IA-3 | Relaciones R1–R5 con Mascotas e Identidad como proveedores de Adopciones y ACL frente al Servicio de Mapas | `docs/dominio/responsabilidades-contextos.md` | Aceptado, **ajustado por IA-11** (2026-10-09) | Refleja quién necesita qué dato y protege los datos personales en Identidad |
| IA-4 | R1 (disponibilidad de mascota) síncrona en proceso, no por eventos | `docs/integracion/sincrono-vs-asincrono.md` | Aceptado | Una copia desactualizada permitiría asignar dos veces la misma mascota (QA-02) |
| IA-5 | Introducir `/api/v1` antes del primer cliente, no ahora | `docs/integracion/contrato-api.yaml` | Aceptado | No hay consumidores externos todavía; versionar ahora no protege a nadie |
| IA-6 | Eventos aceptados: `SolicitudAdopcionCreada`, `SolicitudAdopcionAvanzoDeEtapa`, `AdopcionConcretada`, `ConsentimientoRevocado` | `docs/integracion/eventos-candidatos.md` §1 | Aceptado | Son hechos del dominio con un consumidor concreto que puede enterarse después |
| IA-7 | Eventos rechazados: interacciones de interfaz, consultas, CRUD técnico y los que romperían QA-02 | `docs/integracion/eventos-candidatos.md` §2 | Aceptado | No son hechos del dominio o romperían QA-02 |
| IA-8 | No adoptar CQRS ni Event Sourcing | `docs/integracion/cqrs-event-sourcing.md` | Aceptado | Ninguno resuelve un problema medido y su costo es desproporcionado para el equipo (DA-03) |
| IA-9 | No introducir mensajería ni broker en ningún flujo actual | `docs/integracion/sincrono-vs-asincrono.md`, ADR-03 | Aceptado | Ningún flujo actual lo necesita; agregaría infraestructura (DA-03) |

---

## 2. Hallazgos verificados por ejecución (no son opinión de la IA)

| Hallazgo | Evidencia |
|---|---|
| `GET /api/mascotas/buscar` devuelve un cuerpo JSON con `Content-Type: text/plain` | `experimentos/spike-s10/contrato/verificacion-endpoints.txt` |
| No existe endpoint de lectura de solicitudes (`GET /api/adopciones` → 405) | Mismo archivo |
| Parámetros faltantes o no numéricos en la búsqueda → 400 con el error por defecto de Spring | Mismo archivo |

## 3. No verificado

- La respuesta 500 de `POST /api/adopciones` ante un fallo real de base de datos (no se puede provocar sin modificar el código).
- El costo de la llamada síncrona R1: `MascotaService` no existe todavía.
- Ninguna de las relaciones R1–R5 está implementada; el Context Map describe responsabilidades y decisiones, no código existente (salvo Adopciones y el endpoint simulado de Mascotas).

---

## 4. Revisión tras la retroalimentación del tutor (2026-10-02 → 2026-10-09)

El tutor revisó el repositorio como fuente de evidencia y advirtió que usar
los módulos de `dossier/15` (to-be) como respuesta al análisis del dominio
solo "descubre la decisión que ya estaba tomada". Señaló además que lo
único demostrado en el código es la relación Solicitud ↔ Etapa, que
mascotas, veterinarias y consentimiento no tienen implementación, y dejó
preguntas de negocio para el equipo.

| # | Propuesta de la IA | Dónde | Decisión del equipo | Razón |
|---|---|---|---|---|
| IA-10 | Reconstruir el modelo desde la evidencia: inventario RO1–RO6 (hecho / inferencia / faltante), glosario, inconsistencias C1–C5 y decisiones de negocio D1–D5 respondidas por el equipo. Resultado: cuatro contextos (Adopciones, Mascotas, Atención veterinaria, Identidad); Notificaciones queda fuera del modelo | `docs/dominio/modelo-dominio.md`, `subdominios.md` | Aceptado | Cada frontera se apoya en código o en una decisión explícita del equipo, no en el diseño previo |
| IA-11 | Ajustar relaciones: R1 incluye custodio y `marcarAdoptada`; R2 usa la autorización de datos (D5); R3 pasa a Atención veterinaria; se agregan R6 (Identidad → Mascotas) y R7 (Identidad → Atención veterinaria); R4 queda como diseño de evento hacia un consumidor futuro | `docs/dominio/responsabilidades-contextos.md`, `docs/integracion/sincrono-vs-asincrono.md` | Aceptado | Mantiene la numeración usada en integración y refleja D3–D5 |
| IA-12 | Usar el nombre de tabla del código (`etapa_adopcion`) en los documentos del Módulo 5 y no editar los de semanas anteriores | Documentos del Módulo 5 | Aceptado | El código es la fuente de verdad; los documentos previos se conservan como registro histórico (C2) |

**Rechazado o corregido por el equipo en esta revisión:**

- El primer borrador de `dossier/18-modelo-dominio.md` (2026-10-02; archivo
  retirado el 2026-10-09, su contenido vigente está en `docs/dominio/modelo-dominio.md`) también
  partía de los módulos to-be y clasificaba subdominios sin evidencia. Se
  descartó y se reescribió con el método de IA-10.

**Respondido por el equipo (2026-10-09):** P1–P4, registradas como decisiones
D6–D9 en `modelo-dominio.md` §5 (IA-13).

| # | Propuesta de la IA | Dónde | Decisión del equipo | Razón |
|---|---|---|---|---|
| IA-13 | Registrar las respuestas del equipo a P1–P4 como D6–D9 y propagar sus consecuencias: estados Pendiente/Activa, solo "Disponible" se solicita, regla de mismo municipio en Adopciones, `marcarEnTratamiento` desde Atención veterinaria hacia Mascotas | `docs/dominio/`, `docs/integracion/sincrono-vs-asincrono.md` | Aceptado | Las reglas las definió el equipo; la IA solo las ubicó en el contexto dueño |

**Pendiente de decisión del equipo:** P6 y P7 de `modelo-dominio.md` §7.

---

## 5. Entregable 2 — encuadre de la decisión y spike de integración (2026-10-09)

| # | Propuesta de la IA | Dónde | Decisión del equipo | Razón |
|---|---|---|---|---|
| IA-14 | Presentar la alternativa A como la que se **ensaya primero**, no como "la mejor", y explicar por qué en un monolito modular la alternativa síncrona es una llamada en proceso y no REST por HTTP | `docs/integracion/sincrono-vs-asincrono.md` §1 | Pendiente de revisión | Sigue el encuadre del curso: la decisión es una hipótesis que el spike valida o refuta |
| IA-15 | Plantear un spike de integración porque el spike 1 no evaluó la decisión de integración; el equipo eligió la regla D10 (opción 2) y la especificación quedó preregistrada con métricas Y1–Y7 | `docs/integracion/sincrono-vs-asincrono.md` §4, `experimentos/08-spike-integracion-especificacion.md` | Pendiente de revisión | El veredicto del spike 1 declara que no evalúa la Decisión 3 de ADR-03 |

---

Revisado por: Charry Ríos Daniel Estiven y Kevin Steven Torres Caro · Fecha: 2026-10-03

Sección 4 — Revisado por: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven · Fecha: 2026-10-09

Sección 5 — revisión pendiente de firma del equipo.
