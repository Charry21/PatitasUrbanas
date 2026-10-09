# Modelo del dominio — evidencia y decisiones
## Módulo 5 · Entregable 1 — Modelo del dominio y Context Map

---

## 1. Propósito y método

Este documento es la **base** del Entregable 1. Reconstruye el dominio de
Patitas Urbanas a partir de **evidencia del sistema real**, no a partir del
diseño modular to-be (`dossier/15-diseno-modular-s7.md`). Partir del to-be
solo habría confirmado una decisión tomada antes; la revisión del tutor del
2026-10-02 lo señaló explícitamente (ver
[`registro-ia-modulo5.md`](../integracion/registro-ia-modulo5.md) §4).

El orden del análisis es:

1. Inventario de responsabilidades observables en el repositorio (§2).
2. Términos ambiguos e inconsistencias encontradas (§3, §4).
3. Decisiones de negocio del equipo (D1–D9) para resolver lo que el
   repositorio no demuestra (§5).
4. Contextos resultantes (§6). El detalle de cada contexto, las relaciones
   y el Context Map están en
   [`responsabilidades-contextos.md`](./responsabilidades-contextos.md);
   la clasificación de subdominios, en [`subdominios.md`](./subdominios.md).

Cada afirmación se marca como:

- **HECHO:** demostrado por código, prueba o documento del repositorio.
- **INFERENCIA:** se deduce de los hechos, pero no está demostrado.
- **DECISIÓN DEL EQUIPO:** regla de negocio definida por el equipo en §5;
  no está todavía en el código.
- **FALTANTE:** ni el repositorio ni el equipo lo han definido.

Alcance de la evidencia: rama `main` en el commit `e4e0ece`.

---

## 2. Inventario de responsabilidades observables

### RO1. Registrar una solicitud de adopción

- **HECHO:** `AdopcionService.crearSolicitudConEtapaInicial` crea y
  persiste una `SolicitudAdopcion` con `estado` y `fechaCreacion`
  ([AdopcionService.java](../../app/src/main/java/com/patitasurbanas/api/adopciones/AdopcionService.java),
  [SolicitudAdopcion.java](../../app/src/main/java/com/patitasurbanas/api/adopciones/model/SolicitudAdopcion.java)).
  Si no se envía estado, el código usa `PENDIENTE`.
- **FALTANTE en el código:** la solicitud no referencia ni al adoptante
  ni a la mascota.

### RO2. Registrar la etapa de una solicitud

- **HECHO:** `EtapaAdopcion` tiene `nombreEtapa`, `fechaCambio` y una
  relación `ManyToOne` obligatoria con la solicitud (FK
  `solicitud_adopcion_id`, tabla `etapa_adopcion`)
  ([EtapaAdopcion.java](../../app/src/main/java/com/patitasurbanas/api/adopciones/model/EtapaAdopcion.java)).
  Hoy solo se crea la etapa inicial (`SOLICITUD_RECIBIDA` por defecto);
  no hay operación para registrar etapas siguientes.

### RO3. Mantener la consistencia entre solicitud y etapa

- **HECHO:** solicitud y etapa se crean en un único `@Transactional`, y
  [`AdopcionControllerRollbackIntegrationTest`](../../app/src/test/java/com/patitasurbanas/api/controller/AdopcionControllerRollbackIntegrationTest.java)
  verifica que un fallo revierte ambas. Responde al driver QA-02
  ([`02-stakeholders-drivers.md`](../../dossier/02-stakeholders-drivers.md)).
- **INFERENCIA:** hoy la operación trata solicitud y etapa como una
  unidad. Esto por sí solo no prueba que pertenezcan a la misma frontera
  conceptual; la decisión D1 lo resuelve.

### RO4. Consultar mascotas

- **HECHO:** existe `MascotaController` (`GET /api/mascotas/buscar`), pero
  devuelve una respuesta fija; el C4 lo documenta como simulación
  ([MascotaController.java](../../app/src/main/java/com/patitasurbanas/api/mascotas/MascotaController.java),
  [`07-c4-componentes.md`](../../dossier/07-c4-componentes.md)).
- **FALTANTE en el código:** entidad `Mascota`, su estado, su
  disponibilidad y su relación con una solicitud.

### RO5. Servicios veterinarios

- **HECHO:** solo como intención. El propósito del sistema menciona
  integrar servicios veterinarios
  ([`01-contexto-sistema.md`](../../dossier/01-contexto-sistema.md)) y
  `dossier/15` declara `veterinarias/` sin código.
- **FALTANTE en el código:** cualquier operación veterinaria.

### RO6. Consentimiento y control de acceso

- **HECHO:** solo como driver y restricción. QA-01 exige un Opt-In
  explícito al registrarse y negar escrituras sin permisos; el contexto
  impone la Ley 1581 de 2012.
- **FALTANTE en el código:** usuarios, roles, consentimientos y
  autorización.

### Dependencias demostradas

La única relación respaldada a la vez por modelo, servicio, persistencia y
prueba es **Solicitud → Etapa**. Cualquier relación con mascotas,
veterinarias o usuarios es hoy conceptual.

---

## 3. Términos que necesitaban definición

| Término | Lo que muestra el repositorio | Definición adoptada |
|---|---|---|
| Estado de la solicitud | Campo `String`; valor por defecto `PENDIENTE` | Resultado global de la solicitud: Pendiente, Activa, Aprobada, Rechazada, Cancelada (D1, D7) |
| Etapa | `nombreEtapa` + `fechaCambio`; valor por defecto `SOLICITUD_RECIBIDA` | Paso del proceso; el conjunto de etapas es el historial (D1) |
| Mascota | Solo endpoint simulado | Animal con ciclo de vida propio, independiente de las solicitudes (D3) |
| Fundación / refugio | Se usan en distintos documentos | Mismo rol: custodio del animal (D4) |
| Veterinaria | Actor y módulo futuro | Participante con rol de soporte médico, sin autoridad sobre la adopción (D4) |
| Consentimiento | Opt-In en QA-01 | Dos conceptos distintos: autorización de tratamiento de datos y compromiso de adopción (D5) |
| Disponible | Aparece en QA-03 ("mascotas disponibles") | Único estado de la mascota que permite iniciar una solicitud (D6) |
| Pendiente / Activa | `PENDIENTE` en el código; "Activa" en D1 | Dos estados distintos: Pendiente = nadie la ha revisado; Activa = un custodio la está revisando (D7) |
| Ubicación | Parámetros `lat`, `lng`, `radio` del endpoint simulado | Sirve para buscar y además limita la adopción al mismo municipio o área metropolitana (D8) |
| Adoptante / ciudadano / usuario final | Usados como sinónimos | **FALTANTE**; se tratan como el mismo actor hasta que se decida lo contrario |

---

## 4. Inconsistencias encontradas

| # | Inconsistencia | Evidencia | Tratamiento |
|---|---|---|---|
| C1 | El C4 de contenedores llama "Microservicio" al backend; el diseño modular dice que es un monolito | [`06-c4-contenedores.md`](../../dossier/06-c4-contenedores.md) vs. `dossier/15` §2 (P-04) | Se usa "monolito". El C4 es un documento de semanas anteriores y no se edita aquí |
| C2 | Parte de la documentación dice `etapas_adopcion`; el código usa `etapa_adopcion` | `@Table(name = "etapa_adopcion")` | Se usa el nombre del código. Corregido en los documentos del Módulo 5; los de semanas anteriores (`dossier/01`, `02`, ADR-03) conservan el error como registro histórico |
| C3 | El propósito promete integración veterinaria; no hay código | `dossier/01` §1 vs. `dossier/15` §9 | Atención veterinaria entra al modelo como decisión (D4), no como hecho |
| C4 | QA-03 describe catálogo y clustering geográfico; el endpoint es simulado | QA-03 vs. `MascotaController` | La regla de negocio de ubicación ya está definida (D8); la búsqueda geográfica sigue sin implementarse |
| C5 | Los estados definidos en D1 no incluyen `PENDIENTE`, que es el valor por defecto del código | D1 vs. `AdopcionService` | **Resuelta** (D7): `PENDIENTE` es el estado inicial correcto; el código es coherente con el modelo |

---

## 5. Decisiones de negocio del equipo

Estas reglas no salen del repositorio; las define el equipo para cerrar lo
que el código no demuestra.

**D1 — Estado y etapa son conceptos distintos.**
El *estado* es el resultado global de la solicitud (Pendiente, Activa,
Aprobada, Rechazada, Cancelada; ver D7). La *etapa* es el paso del proceso en que está
(Revisión de formulario, Entrevista, Visita domiciliaria). Las etapas
forman el historial cronológico de la solicitud.
*Consecuencia:* la etapa es parte de la solicitud, no una preocupación
separada; solicitud y etapa comparten frontera (RO3).
*Brecha con el código:* `EtapaAdopcion` no registra quién hizo el cambio y
no existe operación para añadir etapas después de la inicial.

**D2 — Toda solicitud es por una mascota concreta.**
No existe un proceso de pre-aprobación de adoptantes independiente, así que
una solicitud no puede existir sin el identificador de una mascota.
*Brecha con el código:* `SolicitudAdopcion` no tiene esa referencia.

**D3 — La mascota tiene su propio ciclo de vida.**
Su estado (En tratamiento, Extraviada, Cuarentena, Fallecida, etc.) cambia
aunque no exista ninguna solicitud.
*Consecuencia:* Mascota y Solicitud cambian por razones distintas; es la
principal evidencia para separarlas.

**D4 — Solo el custodio aprueba o rechaza.**
Fundación y refugio cumplen el mismo rol: custodio legal del animal, con
autoridad para aprobar o rechazar solicitudes. La veterinaria registra el
historial clínico, programa tratamientos y certifica el estado de salud,
pero no decide sobre la adopción.

**D5 — Hay dos consentimientos distintos.**
1. *Autorización de tratamiento de datos* (Ley 1581 de 2012): se otorga al
   registrarse y aplica a toda la plataforma.
2. *Compromiso de adopción*: se acepta al final de la solicitud, asume las
   responsabilidades de bienestar animal (referencia: Ley 1774 de 2016) y
   es obligatorio para ejecutar la etapa final.

*Consecuencia:* el primero pertenece a Identidad; el segundo, a Adopciones.

**D6 — Solo una mascota "Disponible" puede solicitarse.**
"Disponible" es el único estado que permite iniciar una solicitud.
Significa que el animal superó todos los filtros previos: está sano,
esterilizado, rehabilitado y legalmente libre para ser entregado. Cualquier
otro estado (En tratamiento, Reservada, Adoptada, Cuarentena…) bloquea la
solicitud.
*Consecuencia:* la regla "se puede adoptar" se reduce a una pregunta a
Mascotas: ¿su estado es Disponible? (relación R1). El estado lo sigue
decidiendo Mascotas.

**D7 — Pendiente y Activa son estados distintos.**
*Pendiente*: el adoptante envió la solicitud y nadie la ha revisado.
*Activa* (en proceso): un custodio la tomó y la está revisando (llamadas,
documentos, entrevista). Una solicitud pasa de Pendiente a Activa cuando
empieza su revisión.
*Consecuencia:* resuelve C5. El valor por defecto `PENDIENTE` del código es
el estado inicial correcto. Los estados de la solicitud son: Pendiente →
Activa → Aprobada / Rechazada, y Cancelada.

**D8 — La adopción se limita al mismo municipio o área metropolitana.**
La ubicación sirve para buscar mascotas cercanas y además impone una regla:
el proceso exige una visita domiciliaria antes de la entrega y visitas de
seguimiento después, y las fundaciones no tienen cómo hacerlas en otras
regiones.
*Consecuencia:* la ubicación de la mascota (municipio y coordenadas para
buscar) pertenece a Mascotas; el municipio del adoptante, a Identidad; la
regla "mismo municipio" es del proceso de adopción y pertenece a
Adopciones, que la valida con datos de los otros dos (R1, R2). Las visitas
de seguimiento son etapas posteriores a la entrega (D1).

**D9 — La veterinaria puede poner a una mascota "En tratamiento".**
Si la veterinaria detecta una enfermedad, registra el diagnóstico y cambia
el estado del animal a "En tratamiento" sin esperar al custodio. Así nadie
puede solicitar una mascota enferma mientras la fundación lee el reporte.
La veterinaria no aprueba adopciones (D4), pero sí puede pausarlas por
salud.
*Consecuencia:* el estado sigue siendo de Mascotas (un solo dueño). Atención
veterinaria lo cambia llamando al servicio público de Mascotas, igual que
Adopciones con `marcarAdoptada` (R3). Identidad confirma que quien lo pide
tiene rol de veterinaria (R7).

---

## 6. Contextos resultantes

De la evidencia (§2) y las decisiones (§5) emergen **cuatro** contextos:

| Contexto | Posee | No posee | Respaldo |
|---|---|---|---|
| **Adopciones** | Solicitud, estado (D7), etapa (historial), compromiso de adopción, regla de mismo municipio (D8) | Ciclo de vida de la mascota, autorización de datos, identidad del adoptante | Código (RO1–RO3) + D1, D2, D5, D7, D8 |
| **Mascotas** | Mascota, estado de la mascota (incluido Disponible), custodio, ubicación | Solicitudes y etapas, historial clínico | D3, D4, D6, D8 |
| **Atención veterinaria** | Historial clínico, diagnóstico, tratamiento, certificado de salud | Aprobación de solicitudes; el estado de la mascota (puede pedir "En tratamiento", pero lo registra Mascotas) | D4, D9 |
| **Identidad** | Participante (adoptante, custodio, veterinaria), rol, municipio del participante, autorización de tratamiento de datos | Compromiso de adopción, estado de mascotas | QA-01 (RO6) + D4, D5, D8 |

Justificación de cada frontera, relaciones y Context Map:
[`responsabilidades-contextos.md`](./responsabilidades-contextos.md).

### Fuera del modelo

- **Notificaciones:** se discutió en el mini-comité de Semana 8 y aparece
  como consumidor de eventos en
  [`eventos-candidatos.md`](../integracion/eventos-candidatos.md), pero no
  tiene código ni reglas de negocio propias. Se trata como **consumidor
  futuro**, no como contexto.
- **Donaciones y chat:** mencionados en `dossier/15` como ideas futuras, sin
  caso de uso definido.
- **Búsqueda geográfica real:** la regla de ubicación ya está definida (D8),
  pero la búsqueda (QA-03) sigue simulada (C4).

---

## 7. Preguntas abiertas

| # | Pregunta | Estado |
|---|---|---|
| P1 | ¿Qué estados de la mascota permiten crear una solicitud? ¿Qué significa "disponible"? | **Resuelta** (D6) |
| P2 | ¿`PENDIENTE` equivale a "Activa" o es otro estado? | **Resuelta** (D7) |
| P3 | ¿La geolocalización cambia alguna regla de negocio o solo sirve para buscar? | **Resuelta** (D8) |
| P4 | ¿Una veterinaria puede cambiar el estado de la mascota o solo lo informa? | **Resuelta** (D9) |
| P5 | Cuando se aprueba una adopción, ¿qué le pasa al estado de la mascota y quién lo cambia? | **Resuelta:** Adopciones llama de forma síncrona a `MascotaService.marcarAdoptada(mascotaId)` en la misma transacción; Mascotas cambia su propio estado ([`eventos-candidatos.md`](../integracion/eventos-candidatos.md) §2) |
| P6 | ¿Quién pone a una mascota en "Reservada" y cuándo? ¿Puede haber varias solicitudes Pendientes o Activas para la misma mascota? | Abierta. Define si crear o activar una solicitud cambia el estado de la mascota |
| P7 | Si una mascota pasa a "En tratamiento" (D9) mientras tiene solicitudes Pendientes o Activas, ¿qué les pasa a esas solicitudes? | Abierta. Si se pausan, Adopciones necesita enterarse del cambio; es un candidato a evento (`MascotaPuestaEnTratamiento`) |

---

## 8. Referencias

- [`subdominios.md`](./subdominios.md) — clasificación de subdominios.
- [`responsabilidades-contextos.md`](./responsabilidades-contextos.md) — Posee / No posee, relaciones y Context Map.
- `dossier/01-contexto-sistema.md`, `dossier/02-stakeholders-drivers.md`, `dossier/05`–`07` (C4 as-is)
- `dossier/15-diseno-modular-s7.md` (to-be; usado solo para contrastar, no como punto de partida)
- `adr/adr-02-modularidad.md`, `adr/adr-03-limites-y-comunicacion-modulos.md`

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 10 · Módulo 5 · Arquitectura de Software*
