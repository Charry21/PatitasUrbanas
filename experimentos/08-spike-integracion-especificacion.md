# Especificación del Spike 2 — Integración Adopciones ↔ Mascotas

> **Preregistro.** Este documento fija la hipótesis, las métricas, los
> umbrales y el protocolo **antes** de escribir código o medir. El commit
> que lo integra a `main` es el preregistro; su hora de fusión queda en el
> PR de GitHub. Después de esa fusión, las secciones 1–7 no se modifican.
> Si algo tiene que cambiar, se registra como desviación en el documento de
> resultados.

---

## 1. Decisión que se pone a prueba

**ADR:** [ADR-03](../adr/adr-03-limites-y-comunicacion-modulos.md),
Decisión 3: comunicación **síncrona en proceso** entre módulos (alternativa
A). El spike 1 no la evaluó: su veredicto lo declara expresamente
([`06-spike-resultado-s10.md`](./06-spike-resultado-s10.md) §7).

**Pregunta de integración** ([`sincrono-vs-asincrono.md`](../docs/integracion/sincrono-vs-asincrono.md) §1):
¿cómo debe enterarse Adopciones de que una mascota puede ser adoptada? Se
ensaya primero la alternativa A, con Adopciones llamando a la interfaz
pública de Mascotas dentro de su transacción.

**Regla de dominio implicada:** D10
([`modelo-dominio.md`](../docs/dominio/modelo-dominio.md) §5). Una mascota
puede tener varias solicitudes abiertas. Al aprobar una, la mascota deja de
estar Disponible y las demás se rechazan; como máximo puede haber una
solicitud aprobada por mascota. También aplica D6: solo se puede solicitar
una mascota Disponible.

**Por qué esta regla pone a prueba la decisión de integración.** La
alternativa A promete que Adopciones decide con el estado **actual** de la
mascota. Si dos custodios aprueban a la vez dos solicitudes de la misma
mascota, ambas operaciones consultan el estado casi al mismo tiempo. Si las
dos ven "Disponible", la promesa de A no se cumple y la regla D10 se rompe.

**Riesgo identificado antes de medir.** PostgreSQL trabaja por defecto con
aislamiento *read committed*. Con ese nivel, dos transacciones simultáneas
pueden leer el mismo estado antes de que alguna lo cambie. Por eso se
preregistran **dos condiciones**: A tal como está especificada (A0) y A con
un bloqueo explícito de la fila de la mascota (A1). No se anticipa cuál
resultado se obtendrá.

---

## 2. Cambio acotado (modificación X)

Se implementa en la rama `spike/integracion-r1`, creada desde el commit de
`main` que fusiona esta especificación. Ese commit se registra como **commit
base** en el documento de resultados.

**Dentro del cambio:**

- `mascotas/`: entidad `Mascota` con `id`, `estado` (`DISPONIBLE`,
  `RESERVADA`, `EN_TRATAMIENTO`, `ADOPTADA`), `MascotaRepository` y
  `MascotaService` con:
  - `consultarDisponibilidad(mascotaId)`, que devuelve un DTO;
  - `retirarDeDisponibles(mascotaId)`, que cambia el estado a `RESERVADA`.
    Este valor es **provisional para el spike** y no decide P8: las
    métricas solo exigen que el estado deje de ser `DISPONIBLE`.
- `shared/dto/`: `DisponibilidadMascota`.
- `adopciones/`:
  - `SolicitudAdopcion` recibe `mascotaId` (D2).
  - `POST /api/adopciones` exige `mascotaId` y consulta la disponibilidad
    dentro de la transacción de TRX-02 (D6).
  - Nueva operación `aprobarSolicitud(idSolicitud)` y su endpoint
    `POST /api/adopciones/{id}/aprobar`. Dentro de una sola transacción
    `@Transactional`: consulta la disponibilidad, marca la solicitud como
    `APROBADA`, llama a `retirarDeDisponibles` y marca como `RECHAZADA` las
    demás solicitudes abiertas de esa mascota (D10).
- **Condición A0:** sin bloqueo explícito.
- **Condición A1:** idéntica a A0, salvo que `retirarDeDisponibles` y la
  consulta de la operación de aprobar leen la mascota con bloqueo pesimista
  (`@Lock(PESSIMISTIC_WRITE)`, es decir, `SELECT … FOR UPDATE`). Es el único
  cambio entre A0 y A1, y queda en un commit propio.
- Pruebas y scripts de medición. Los scripts y las salidas van en
  `experimentos/spike-integracion/`; las pruebas, en `app/src/test/`.

**Fuera del cambio:** autenticación y rol de quien aprueba (R2, D4), regla
territorial (D8), compromiso de adopción (D5), etapas posteriores a la
inicial, Atención veterinaria (R3), eventos y Notificaciones, bus o broker de
mensajes, cambios en `docker-compose.yml`, y el estado definitivo tras
aprobar (P8). No se modifican `pom.xml` ni `application.properties`.

**Contrato HTTP:** `POST /api/adopciones` pasa a exigir `mascotaId`, así que
la solicitud S1 del spike 1 (sin parámetros) dejará de ser válida. Es un
cambio de contrato esperado por D2. `contrato-api.yaml` solo se actualiza si
el cambio se integra a `main`.

---

## 3. Hipótesis, métricas y umbrales

### Hipótesis

**H-A0.** Con la alternativa A tal como está especificada (consulta y cambio
de estado síncronos dentro de la misma transacción, sin bloqueo explícito),
en **31 de 31** ráfagas de 10 aprobaciones simultáneas para la misma mascota
se aprueba **exactamente una** solicitud, la mascota deja de estar
Disponible y las otras nueve quedan rechazadas.

**H-A1.** Lo mismo con la condición A1 (bloqueo pesimista de la fila de la
mascota).

### Métricas

| Métrica | Qué mide | Cómo | Umbral de confirmación |
|---|---|---|---|
| **Y1 — Aprobaciones por ráfaga** | D10 bajo concurrencia | Prueba de integración contra PostgreSQL: se siembra 1 mascota `DISPONIBLE` y 10 solicitudes `PENDIENTE`; 10 hilos invocan `aprobarSolicitud` a la vez (liberados por un `CountDownLatch`); se cuentan las solicitudes `APROBADA` de esa mascota | Exactamente 1 en **31/31** ráfagas, para cada condición por separado |
| **Y2 — Estado final coherente** | Que nada quede a medias tras la ráfaga | Consulta SQL al terminar cada ráfaga: mascota ≠ `DISPONIBLE`; 1 `APROBADA`; 9 `RECHAZADA`; 0 `PENDIENTE` o `ACTIVA` | 0 ráfagas incoherentes de 31 |
| **Y3 — Atomicidad entre módulos** | Si `retirarDeDisponibles` falla, la aprobación también se revierte | Prueba que fuerza una excepción en `retirarDeDisponibles` (mismo mecanismo que `test-fallo`) y verifica el estado | 0 solicitudes `APROBADA` con la mascota `DISPONIBLE`, en 3/3 corridas |
| **Y4 — Regla D6 al crear** | Solo se crean solicitudes para mascotas Disponibles | Prueba con mascotas en `DISPONIBLE`, `RESERVADA`, `EN_TRATAMIENTO`, `ADOPTADA` e inexistente | 0 solicitudes creadas para mascotas no Disponibles; 1 para la Disponible |
| **Y5 — Fronteras (ADR-02)** | Que Adopciones use solo la API pública de Mascotas | `experimentos/spike-s10/revisar_modulos.py` (validado en el spike 1), ampliado con las clases nuevas | 0 imports prohibidos |
| **Y6 — Costo de la llamada síncrona al crear** | Cuánto agrega `consultarDisponibilidad` a `POST /api/adopciones` | `MEDICION_S6_CONTROLADOR_MS` antes (commit base) y después (A0) | Aumento de la mediana **≤ 5 ms** |
| **Y7 — Carga (BIZ-01)** | Que la consulta síncrona no degrade la concurrencia de creación | `experimentos/escenario-concurrencia-biz01.js` adaptado para enviar `mascotaId` | p95 < 1000 ms y 0 errores 500/503/408, como en BIZ-01 |

**Sobre Y6.** La referencia previa es la mediana de 10,32 ms medida en
Semana 7 (`resultado-medicion-controlador-s7.txt`, 7 peticiones). No se usa
como línea base: el antes y el después se miden en la misma sesión y el
mismo entorno, según §5.

### Criterios de confirmación y refutación

| Resultado | Qué se concluye |
|---|---|
| H-A0 confirmada (Y1 y Y2 con A0) e Y3–Y7 cumplen | La alternativa A, tal como está especificada, es suficiente para D10 |
| H-A0 refutada, H-A1 confirmada, e Y3–Y7 cumplen | La alternativa A es válida **solo con bloqueo explícito**. Se registra en un ADR nuevo como condición de la Decisión 3 de ADR-03 |
| H-A0 y H-A1 refutadas | La alternativa A no garantiza D10 en las condiciones medidas. Se reabre la decisión de integración |
| Falla Y3, Y4 o Y5 | Error de implementación del spike, no de la alternativa: se corrige, se registra como desviación y se repite la medición |
| Falla Y6 o Y7 con Y1–Y5 cumplidas | La alternativa A es correcta, pero su costo supera el umbral. Se registra y se evalúa la alternativa B |

Basta con **una** ráfaga incoherente (Y1 o Y2) para refutar la hipótesis de
esa condición. No se promedian ráfagas.

---

## 4. Instrumentos y su validación

| Instrumento | Validación previa a la medición |
|---|---|
| Prueba de concurrencia (Y1, Y2) | Debe **detectar** una doble aprobación cuando existe. Antes de medir, se ejecuta una vez en una rama descartable (`spike/control-concurrencia-descartable`) con una versión que aprueba sin consultar el estado de la mascota; la prueba debe registrar más de 1 aprobación en al menos una ráfaga. Si no la detecta, Y1 y Y2 no son válidas |
| Consulta SQL de coherencia (Y2) | Se ejecuta sobre un estado sembrado a mano con una inconsistencia conocida (2 solicitudes `APROBADA`) y debe reportarla |
| Script de fronteras (Y5) | Ya validado en el spike 1 (control Y2). Se reutiliza sin cambiar su criterio; solo se agregan las clases nuevas al mapeo |
| `MEDICION_S6_CONTROLADOR_MS` (Y6) | Instrumentación existente desde el PR #41 |

---

## 5. Condiciones de medición

- **Entorno:** el mismo para todas las mediciones de este spike. Se
  registran `java -version`, `mvn -v`, `docker version` y
  `SELECT version();` de PostgreSQL en `experimentos/spike-integracion/entorno.txt`.
- **Base de datos:** PostgreSQL 16 del `docker-compose.yml`, con el
  aislamiento por defecto (*read committed*). No se cambia el nivel de
  aislamiento.
- **Antes de cada bloque:** `docker compose down -v` y
  `docker compose up -d postgres_db`, esperando el estado `healthy`.
- **Y1/Y2:** 31 ráfagas por condición (número impar, como exige la
  metodología del curso), cada una con una mascota nueva. Se descarta una
  ráfaga inicial de calentamiento por condición, registrada aparte.
- **Y3:** 3 corridas.
- **Y4, Y5:** 1 corrida cada una (son deterministas).
- **Y6:** 1 serie descartada por calentamiento + 3 series válidas de 30
  peticiones, antes y después; se compara la mediana de las series válidas.
- **Y7:** 1 corrida de calentamiento descartada + 3 corridas válidas.
- **Orden:** línea base Y6 → control de instrumentos → condición A0 →
  condición A1. Cada paso en su propio commit.

---

## 6. Uso de IA

Si la implementación o la medición se delegan a un agente (por ejemplo,
Claude Code), se registra la herramienta, el modelo y el prompt exacto en
una auditoría con el formato de
[`05-auditoria-ia-s9.md`](./05-auditoria-ia-s9.md) (EDAV). El agente no
puede cambiar esta especificación, los umbrales ni los criterios. Su salida
no es aceptación automática: requiere auditoría humana antes de integrarse.

---

## 7. Limitaciones conocidas de antemano

- La concurrencia se prueba con hilos dentro de una sola JVM contra una sola
  base de datos. No representa varios servidores de aplicación.
- 31 ráfagas de 10 hilos no demuestran que la carrera sea imposible; solo
  que no apareció en esas condiciones.
- El estado `RESERVADA` es provisional (P8). No se prueba qué pasa al
  concretar la adopción.
- Sin autenticación: no se verifica que quien aprueba sea el custodio (D4).
- La alternativa B (eventos) no se ensaya en este spike.

---

## Resultado

Pendiente: se registrará en `experimentos/09-spike-integracion-resultado.md`.

## Veredicto

Pendiente.

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 10 · Módulo 5 · Arquitectura de Software*
