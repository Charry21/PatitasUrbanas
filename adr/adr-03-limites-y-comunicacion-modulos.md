# ADR-03 — Límites de Módulo, API Pública y Comunicación entre Módulos
## Patitas Urbanas · Módulo 5

---

## Estado

**Aceptada** (Semana 10, 2026-10-02):

- **Decisión 1 (límites de módulo)** y **Decisión 2 (API pública):**
  aceptadas. El spike soporta la hipótesis con las cinco métricas
  dentro del umbral predefinido (ver "Resultado del spike").
- **Decisión 3 (comunicación síncrona en proceso):** aceptada como
  vigente con condición de revisión. El spike no la evalúa porque no
  existe comunicación entre módulos; la revisión de casos de uso y la
  evaluación de CQRS y consistencia eventual
  (`dossier/17-cqrs-consistencia-eventual-s10.md`) no encuentran
  ninguna necesidad que justifique la comunicación asíncrona.

Especificación del spike (committeada antes de ejecutar):
`experimentos/04-spike-especificacion-s9.md`.
Resultado y veredicto del spike: `experimentos/06-spike-resultado-s10.md`.

Veredicto del spike: **hipótesis soportada** (confirmada), sujeto a la
auditoría humana de `experimentos/05-auditoria-ia-s9.md`.

---

## Contexto

ADR-01 adopta el monolito modular y ADR-02 declara las reglas de
dependencia entre módulos. Ambos quedaron en estado **Ajustada** tras
el mini-comité de Semana 8. Ninguno de los dos decide:

1. cuáles son exactamente los límites de cada módulo (qué clases y qué
   datos le pertenecen);
2. qué parte de cada módulo es su **API pública** (hacia clientes HTTP
   y hacia otros módulos);
3. si los módulos se comunican de forma **síncrona** (llamada directa
   a un servicio público dentro del mismo proceso) o **asíncrona**
   (eventos).

**Estado actual verificado en el código (`main`):**

- Todas las clases están organizadas por capa técnica
  (`controller/`, `service/`, `repository/`, `model/`), no por dominio.
- Endpoints existentes:
  - `POST /api/adopciones` — crea una solicitud de adopción y su
    etapa inicial en una transacción (`@Transactional` en
    `AdopcionService`). Responde `201 Created` con `idSolicitud`,
    `estado`, `etapaInicial`.
  - `POST /api/adopciones/test-fallo` — fuerza un fallo para verificar
    el rollback (QA-02 / TRX-02).
  - `GET /api/mascotas/buscar?lat&lng&radio` — respuesta simulada; no
    existe todavía entidad `Mascota`.
- Hoy no existe ninguna llamada entre módulos: adopciones no consulta
  mascotas ni a la inversa.

**Drivers relevantes** (`dossier/14-comparacion-estilos-s7.md`):

| ID | Driver | Prioridad |
|---|---|---|
| DA-01 | Mantenibilidad: cambiar un módulo sin romper otros | Alta |
| DA-02 | Testeabilidad | Alta |
| DA-03 | Costo operativo proporcional a un equipo de 2 personas | Alta |
| DA-04 | Extensibilidad: agregar módulos sin reescribir lo existente | Media |
| DA-05 | Trazabilidad: cada cambio auditable en Git | Alta |
| QA-02 | Integridad transaccional de TRX-02 (sin registros huérfanos) | Alta |

---

## Problema

> ¿Dónde están los límites de cada módulo, qué expone cada uno y cómo
> se comunican entre sí, de forma que se respeten las reglas de ADR-02
> sin romper la integridad transaccional de TRX-02 ni aumentar el
> costo operativo?

---

## Decisión 1 — Límites de módulo

Los límites siguen el mapeo de `dossier/15-diseno-modular-s7.md` §7:

| Módulo | Le pertenece | Datos propios |
|---|---|---|
| `adopciones/` | `AdopcionController`, `AdopcionService`, `SolicitudAdopcionRepository`, `EtapaAdopcionRepository`, `model/SolicitudAdopcion`, `model/EtapaAdopcion` | tablas `solicitud_adopcion`, `etapas_adopcion` |
| `mascotas/` | `MascotaController` (y, cuando existan, `MascotaService`, `MascotaRepository`, `model/Mascota`) | ninguna todavía |
| `veterinarias/` | declarado, sin clases | ninguna |
| `shared/` | excepciones base, DTOs usados por más de un módulo, utilidades sin lógica de negocio (criterio de admisión de ADR-02) | ninguna |
| `config/` | beans de infraestructura | ninguna |

Cada tabla tiene un único módulo dueño. Ningún módulo lee ni escribe
tablas de otro módulo.

---

## Decisión 2 — API pública de cada módulo

| Módulo | API hacia clientes HTTP | API hacia otros módulos |
|---|---|---|
| `adopciones/` | `POST /api/adopciones`, `POST /api/adopciones/test-fallo` | `AdopcionService` (métodos públicos) |
| `mascotas/` | `GET /api/mascotas/buscar` | `MascotaService` cuando exista |
| `veterinarias/` | ninguna todavía | ninguna todavía |

- Los contratos HTTP (ruta, parámetros, código de estado y estructura
  JSON) **no cambian** con la reorganización de ADR-01. El spike lo
  verifica con la métrica Y3.
- Repositorios y entidades son internos al módulo (ADR-02). Si otro
  módulo necesita datos, se le entregan como DTO de `shared/`.

---

## Decisión 3 — Comunicación entre módulos: síncrona vs. asíncrona

### Alternativas consideradas

| Criterio | A — Síncrona en proceso (llamada a servicio público) | B — Asíncrona con eventos en proceso (`ApplicationEventPublisher`) | C — Asíncrona con broker externo (RabbitMQ/Kafka) |
|---|---|---|---|
| Infraestructura nueva | Ninguna | Ninguna | Broker, configuración, monitoreo |
| Costo operativo (DA-03) | Mínimo | Bajo | Alto para 2 personas |
| Integridad de TRX-02 (QA-02) | La operación queda dentro de una sola transacción | Requiere decidir si el evento se procesa dentro o después del commit | Consistencia eventual; requiere compensaciones o outbox |
| Acoplamiento (DA-01) | El llamador conoce la interfaz del servicio | El emisor no conoce a los consumidores | El emisor no conoce a los consumidores |
| Depuración y pruebas (DA-02) | Directa: una pila de llamadas | Media: flujo indirecto | Difícil: requiere el broker en las pruebas |
| Necesidad actual | Suficiente: hoy no hay llamadas entre módulos | No hay ningún caso de uso que lo requiera | No hay ningún caso de uso que lo requiera |

### Decisión

Se adopta provisionalmente la **Alternativa A — comunicación síncrona
en proceso**, a través de los servicios públicos de cada módulo.
Es coherente con la regla general de ADR-02 ("la comunicación entre
módulos se hace exclusivamente a través de las interfaces de servicio
públicas").

**Razón:** no existe hoy ningún flujo entre módulos que se beneficie
del desacoplamiento temporal; la única operación crítica (TRX-02) es
local a `adopciones/` y necesita atomicidad, que la comunicación
síncrona dentro de una transacción garantiza sin infraestructura nueva.

### Alternativas descartadas o aplazadas

- **B — Eventos en proceso:** aplazada. Se reconsiderará cuando
  aparezca un efecto secundario que no deba bloquear la operación
  principal (por ejemplo, notificar un cambio de estado de una
  solicitud).
- **C — Broker externo:** descartada en este alcance. Viola DA-03
  (infraestructura adicional sin DevOps) y obliga a manejar
  consistencia eventual en TRX-02 sin que exista un driver que lo
  justifique.

---

## Relación con el spike (Semanas 9–10)

El spike especificado en `experimentos/04-spike-especificacion-s9.md`
pone a prueba las Decisiones 1 y 2 de este ADR:

| Decisión de este ADR | Métrica del spike que la evalúa |
|---|---|
| Decisión 1 — Límites de módulo | Y4 (clases en su módulo objetivo = 100%) e Y5 (paquetes que mezclan dominios = 0) |
| Decisión 1 — Reglas de ADR-02 | Y2 (imports prohibidos = 0) |
| Decisión 2 — API pública sin cambios | Y3 (0 diferencias en S1–S3) e Y1 (100% de tests que pasaban siguen pasando) |

La Decisión 3 no se evalúa en este spike: hoy no hay comunicación
entre módulos que medir. Queda condicionada a la condición de
revisión de abajo.

El resultado, las observaciones y el veredicto del spike se registran
en `/experimentos` en Semana 10 y se enlazan desde este ADR.
**Este ADR no se modifica antes de conocer el resultado**, salvo para
registrar ese enlace y el veredicto.

---

## Resultado del spike (Semana 10)

Fuente: `experimentos/06-spike-resultado-s10.md` (evidencia original en
`experimentos/spike-s10/`). Rama de ejecución
`spike/fronteras-modulares-s10` desde `887ccf1`; reorganización en el
commit `1e522df`.

| Decisión | Métrica | Base | Después | Umbral | Resultado |
|---|---|---|---|---|---|
| 1 — Límites de módulo | Y4 | 0/7 (0%) | 7/7 (100%) | 100% | Cumple |
| 1 — Límites de módulo | Y5 | 1 | 0 | 0 | Cumple |
| 1 — Reglas de ADR-02 | Y2 | 0 | 0 | 0 | Cumple (medidor validado con un import inyectado: Y2 = 1) |
| 2 — API pública | Y3 | — | 0 diferencias (9/9) | 0 | Cumple |
| 2 — API pública | Y1 | 2/2 tests | 2/2 tests (3/3 corridas) | 100% | Cumple |

**Contraste con las decisiones:**

- **Decisión 1:** la estructura de paquetes refleja los límites
  declarados (`adopciones/`, `adopciones/model/`, `mascotas/`) y ningún
  paquete mezcla dominios. La parte de "datos propios" (cada tabla con
  un único módulo dueño) no la mide el spike; se mantiene porque ninguna
  clase fuera de `adopciones/` accede a las tablas de adopciones.
- **Decisión 2:** los contratos HTTP de S1–S3 no cambian y ningún
  módulo importa repositorios o modelos de otro. El spike no cubre
  `POST /api/adopciones/test-fallo` fuera de su test ni entradas no
  válidas.
- **Decisión 3:** sin evidencia nueva del spike. Revisada contra los
  casos de uso reales: las únicas operaciones son
  `POST /api/adopciones` (atómica, TRX-02), `POST /api/adopciones/test-fallo`
  y `GET /api/mascotas/buscar` (simulado). Ninguna invoca a otro módulo
  ni tiene efectos secundarios, así que la Alternativa A sigue siendo
  suficiente.

**Alternativas tras el spike:**

| Alternativa | Estado | Por qué |
|---|---|---|
| Decisión 3 — A: síncrona en proceso | Se mantiene | Sin llamadas entre módulos; preserva la atomicidad de TRX-02 |
| Decisión 3 — B: eventos en proceso | Sigue aplazada | Candidata para notificaciones futuras (`dossier/17`, §4.2) |
| Decisión 3 — C: broker externo | Sigue descartada | Viola DA-03; ningún driver la justifica |
| ArchUnit para reforzar fronteras (ADR-02, Alternativa B) | Sigue sin adoptarse | Y2 = 0 sin él; el script del spike puede reutilizarse como verificación manual en PR |

**Desviaciones y límites** (detalle en `06-spike-resultado-s10.md` §5–§6):
ejecución en Linux con Maven local, no en Windows/WSL2; no se construyó
la imagen Docker de la API; Y2 no analiza referencias dentro del mismo
paquete. Ninguna afecta a los criterios de confirmación.

---

## Consecuencias

### Positivas

- Cada tabla y cada clase tiene un único módulo dueño, verificable
  en la estructura de paquetes.
- Los contratos HTTP quedan declarados como estables y verificables.
- No se agrega infraestructura (DA-03).
- La integridad transaccional de TRX-02 se mantiene sin compensaciones.
- **Verificado por el spike:** la reorganización se hizo cambiando solo
  declaraciones `package`/`import` (8 archivos) y sin coste funcional
  observable (Y1 = 100%, Y3 = 0).

### Negativas

- La comunicación síncrona acopla en el tiempo al llamador con el
  servicio llamado: si en el futuro un módulo invoca a otro, un fallo
  del segundo afecta al primero.
- Las fronteras siguen dependiendo de convención y revisión de PR
  (ADR-02); el spike mide una sola reorganización, no garantiza el
  cumplimiento futuro.
- `mascotas/` y `veterinarias/` tienen límites declarados pero casi
  sin código; sus APIs públicas se definirán cuando exista la lógica.
- **Observado en el spike:** `shared/`, `config/` y `veterinarias/` no
  existen como paquetes porque no tienen clases; se crearán con la
  primera clase que les pertenezca.
- **Observado en el spike:** el test de rollback quedó en el paquete de
  test `api.controller`, que ya no existe en producción (hallazgo S1 de
  la auditoría).

---

## Implicaciones de seguridad

La comunicación síncrona en proceso no abre canales de red nuevos: el
perímetro sigue siendo el de ADR-01 (un proceso, una base de datos).
Exponer a otros módulos solo servicios y DTOs, nunca entidades JPA,
limita qué datos personales (Ley 1581 de 2012) cruzan una frontera de
módulo.

La condición del mini-comité de Semana 8 (cifrado en tránsito hacia el
proveedor externo y autenticación explícita entre el monolito y el
microservicio de notificaciones) aplica si se adopta comunicación
asíncrona o un servicio separado para notificaciones. Este ADR no
introduce ninguno de los dos.

---

## Reversibilidad

Alta. Las Decisiones 1 y 2 son organización de paquetes y declaración
de contratos; la Decisión 3 no introduce infraestructura. Pasar a
eventos en proceso (Alternativa B) en el futuro no requiere deshacer
nada de este ADR.

---

## Supuestos y condición de revisión

| Supuesto | Cómo se verifica |
|---|---|
| La reorganización por límites de módulo no cambia los contratos HTTP | Spike, métrica Y3 — **verificado** (0 diferencias en S1–S3) |
| Los límites declarados se pueden materializar sin mezclar dominios en un paquete | Spike, métricas Y4 e Y5 — **verificado** (100% y 0) |
| Ningún flujo actual necesita comunicación asíncrona | Revisión de los casos de uso al agregar cada módulo nuevo — **revisado en Semana 10** (`dossier/17`) |
| Ningún flujo actual necesita CQRS | `dossier/17-cqrs-consistencia-eventual-s10.md` §3 — **revisado en Semana 10** |

**Condición de revisión:** si aparece un caso de uso entre módulos
que no deba bloquear la operación principal (por ejemplo,
notificaciones de cambio de estado de una adopción), se evalúa la
Alternativa B en un ADR nuevo, aplicando la condición de seguridad del
mini-comité de Semana 8.

---

## Referencias

- `adr/adr-01-decision-estilo.md`
- `adr/adr-02-modularidad.md`
- `dossier/14-comparacion-estilos-s7.md`
- `dossier/15-diseno-modular-s7.md`
- `dossier/evidencia-comite-semana8.md`
- `experimentos/04-spike-especificacion-s9.md` — especificación del spike que pone a prueba este ADR.
- `experimentos/05-auditoria-ia-s9.md` — EDAV 2 del trabajo delegado en el spike.
- `experimentos/06-spike-resultado-s10.md` — resultado, desviaciones y veredicto del spike.
- `experimentos/spike-s10/` — scripts y salidas originales de las mediciones.
- `dossier/17-cqrs-consistencia-eventual-s10.md` — evaluación de CQRS y consistencia eventual.

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Fecha: 2026-10-02*
*Semanas 9–10 · Módulo 5 · Arquitectura de Software*

---

## Historial de cambios

| Fecha | Semana | Commit | Cambio |
|---|---|---|---|
| 2026-10-02 | 9 | `403d7b5` | Creación en estado Propuesta, antes de ejecutar el spike |
| 2026-10-02 | 10 | (este commit) | Resultado del spike; estado Aceptada; alternativas, consecuencias y supuestos actualizados; enlace a la evaluación de CQRS y consistencia eventual |
