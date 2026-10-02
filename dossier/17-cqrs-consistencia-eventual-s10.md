# 17 — Aplicabilidad de CQRS y consistencia eventual · Semana 10
## Patitas Urbanas · Módulo 5

---

## 1. Propósito

Evaluar, con el sistema tal como existe hoy, si hay una necesidad real de:

1. **CQRS**: separar el modelo de escritura del modelo de lectura.
2. **Consistencia eventual**: aceptar que algún dato se actualice de forma no inmediata.

La evaluación no implementa ninguno de los dos. Se basa en el código de
`main` después del spike de Semana 10 (paquetes `adopciones/` y
`mascotas/`) y en la evidencia previa del dossier.

---

## 2. Operaciones existentes

| Operación | Tipo | Qué hace | Datos |
|---|---|---|---|
| `POST /api/adopciones` | Escritura | `AdopcionService.crearSolicitudConEtapaInicial` crea una `SolicitudAdopcion` y su `EtapaAdopcion` inicial dentro de un único `@Transactional` | `solicitud_adopcion`, `etapas_adopcion` |
| `POST /api/adopciones/test-fallo` | Escritura (prueba) | Igual que la anterior, pero lanza una excepción entre los dos `save` para comprobar el rollback (QA-02 / TRX-02) | Mismas tablas; no deja datos |
| `GET /api/mascotas/buscar` | Lectura | Respuesta estática simulada; no consulta la base de datos | Ninguno |

Observaciones verificadas en el código:

- No existe **ningún endpoint de lectura sobre datos persistidos**:
  no hay consulta de solicitudes, historial de etapas, listados ni informes.
- La única escritura real afecta a dos tablas de un mismo módulo y
  exige atomicidad (TRX-02: sin registros huérfanos), verificada por
  `AdopcionControllerRollbackIntegrationTest`.
- Las dos hipótesis de localización de Semana 6 quedaron **refutadas**:
  el tiempo de SQL es solo el 2–9% del tiempo total de
  `POST /api/adopciones` (`dossier/10-resultado-hipotesis-s6.md`), y los
  factores externos no dominan (42–48%, caso límite;
  `dossier/12-resultado-hipotesis2-s6.md`). No hay ninguna medición que
  muestre contención entre lecturas y escrituras.

---

## 3. CQRS

### 3.1 Pregunta de análisis

> ¿Qué restricción o necesidad concreta del sistema justificaría mantener
> modelos de lectura y escritura separados, en lugar de compartir el
> mismo modelo?

### 3.2 Necesidades que justificarían CQRS, contrastadas con el sistema

| Necesidad que justificaría CQRS | ¿Existe hoy? | Evidencia |
|---|---|---|
| Lecturas con una forma muy distinta a la del modelo de escritura (vistas agregadas, informes, búsquedas complejas) | No | No hay endpoints de lectura sobre datos persistidos |
| Carga de lectura mucho mayor que la de escritura, que obligue a escalarlas por separado | No | No hay lecturas persistidas; la BD es el 2–9% del tiempo de la única escritura (Semana 6) |
| Lecturas que degradan las escrituras (bloqueos, contención) | No | No existen lecturas sobre las tablas de adopciones que puedan competir |
| Reglas de negocio complejas en escritura que el modelo de lectura complica | No | La escritura crea dos registros con valores por defecto |
| Requisito de auditoría o historial completo de eventos (event sourcing) | No | No hay ningún driver ni escenario de calidad que lo pida |

### 3.3 Consecuencias de introducirlo ahora

- Dos modelos y un mecanismo para sincronizarlos (proyecciones), sin
  ninguna lectura que los use.
- Si la sincronización es asíncrona, aparece consistencia eventual en
  datos que hoy son inmediatos (ver §4).
- Más código y más pruebas para un equipo de 2 personas (DA-03), sin
  mejorar ningún driver medido.

### 3.4 Decisión

**No se aplica CQRS.** Lectura y escritura comparten el modelo de cada
módulo. Ninguna necesidad concreta del sistema actual lo justifica.

**Condiciones de revisión** (cualquiera de ellas reabre la evaluación):

1. Aparece un caso de uso de lectura que agrega datos de varios módulos
   (por ejemplo, un panel de fundaciones con solicitudes por estado y
   datos de mascotas) y el modelo de escritura no puede servirlo sin
   romper las reglas de ADR-02.
2. Una medición muestra que las lecturas degradan las escrituras de
   TRX-02, con un criterio fijado antes de medir, como en Semana 6.
3. Se exige un historial completo e inmutable de cambios de estado de
   una adopción que no se pueda cubrir con la tabla `etapas_adopcion`.

---

## 4. Consistencia eventual

### 4.1 Preguntas de análisis aplicadas a TRX-02 (crear solicitud de adopción)

| Pregunta | Respuesta para el sistema actual |
|---|---|
| ¿Qué información debe estar disponible inmediatamente después de la operación? | La `SolicitudAdopcion` **y** su `EtapaAdopcion` inicial. QA-02 exige que nunca exista una sin la otra; el cliente recibe `idSolicitud` en la respuesta y puede consultarla de inmediato. |
| ¿Qué efecto secundario podría ejecutarse después? | Hoy ninguno: la operación no tiene efectos secundarios. El candidato futuro es **notificar** al usuario o a la fundación el cambio de estado (escenario discutido en el mini-comité de Semana 8). |
| ¿Qué ocurriría si ese proceso fallara? | Si la notificación fuera posterior y fallara, la solicitud seguiría siendo válida; el usuario no se enteraría a tiempo, pero no habría datos corruptos. Si en cambio la **etapa inicial** se creara después y fallara, quedaría una solicitud huérfana: exactamente lo que QA-02 prohíbe. |
| ¿Cómo se detectaría y resolvería una inconsistencia? | Para una notificación: registro de envíos pendientes/fallidos, reintentos idempotentes y una consulta de solicitudes sin notificación. Para la etapa inicial no hay resolución aceptable: por eso debe ser atómica. |
| ¿Qué implicaciones tendría para la integridad transaccional? | Separar solicitud y etapa rompería la atomicidad que hoy garantiza `@Transactional` y que verifica el test de rollback. Un efecto secundario como la notificación, en cambio, puede quedar fuera de la transacción si se publica solo después del commit (por ejemplo, con un evento `AFTER_COMMIT` o una tabla outbox). |

### 4.2 Decisión

- **TRX-02 sigue siendo fuertemente consistente.** Solicitud y etapa
  inicial se escriben en la misma transacción. No se acepta consistencia
  eventual en esta operación.
- **No se introduce consistencia eventual en ninguna operación actual**,
  porque ninguna tiene efectos secundarios.
- **Candidato identificado para el futuro:** las notificaciones de
  cambio de estado. Si se implementan, pueden ser eventualmente
  consistentes respecto a la solicitud, siempre que:
  1. se publiquen solo después del commit de la transacción;
  2. los reintentos sean idempotentes y los fallos queden registrados;
  3. se cumpla la condición del mini-comité de Semana 8 (cifrado en
     tránsito y autenticación entre el monolito y el servicio de
     notificaciones) si el envío sale del proceso.

Esta decisión es coherente con ADR-03, Decisión 3 (comunicación
síncrona en proceso; eventos aplazados hasta que exista un efecto
secundario que no deba bloquear la operación principal).

---

## 5. Resumen

| Concepto | ¿Se aplica hoy? | Razón principal | Se reconsidera si… |
|---|---|---|---|
| CQRS | No | No hay lecturas sobre datos persistidos ni evidencia de contención | Aparece una lectura agregada entre módulos, una medición de contención o un requisito de historial inmutable |
| Consistencia eventual en TRX-02 | No | QA-02 exige atomicidad de solicitud + etapa | No se reconsidera mientras QA-02 siga vigente |
| Consistencia eventual en efectos secundarios | No existen todavía | No hay efectos secundarios | Se implementan notificaciones u otro efecto que no deba bloquear la operación |

---

## Referencias

- `adr/adr-02-modularidad.md`
- `adr/adr-03-limites-y-comunicacion-modulos.md` (Decisión 3)
- `dossier/02-stakeholders-drivers.md` (QA-02, TRX-02)
- `dossier/10-resultado-hipotesis-s6.md`, `dossier/12-resultado-hipotesis2-s6.md`
- `dossier/evidencia-comite-semana8.md`
- `experimentos/06-spike-resultado-s10.md`

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Fecha: 2026-10-02*
*Semana 10 · Módulo 5 · Arquitectura de Software*
