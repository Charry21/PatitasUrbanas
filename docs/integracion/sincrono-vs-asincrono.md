# Síncrono vs. asíncrono — decisión por relación
## Módulo 5 · Entregable 2 — Decisión de integración

La decisión general está en ADR-03, Decisión 3 (comunicación síncrona en
proceso; eventos aplazados). Este documento la aplica **a cada relación del
Context Map** (`docs/dominio/responsabilidades-contextos.md`). No hay una
regla universal: cada relación se decide por lo que necesita saber el
consumidor y cuándo.

---

## 1. Pregunta central

> **¿Cómo debe enterarse Adopciones de que una mascota puede ser adoptada?** (R1)

Es la relación más importante porque toca el contexto núcleo y la regla TRX-02.

| | Alternativa A — Síncrona (llamada en proceso) | Alternativa B — Eventos asíncronos |
|---|---|---|
| **Mecanismo** | `AdopcionService` llama a `MascotaService.consultarDisponibilidad(mascotaId)` antes de crear la solicitud, dentro del mismo proceso. | Mascotas publica `MascotaDisponibilidadCambiada`; Adopciones guarda una copia local de la disponibilidad y la consulta. |
| **Ventaja** | El dato es el actual en el momento de la solicitud; no hay copia que sincronizar. La validación ocurre dentro de la transacción de TRX-02. | Adopciones no depende de que Mascotas responda en ese instante. |
| **Costo / riesgo** | Acoplamiento temporal: si `MascotaService` falla, la solicitud falla. En un monolito este riesgo es bajo: es una llamada a un método en el mismo proceso, sin red. | Copia replicada y consistencia eventual: se podría aceptar una solicitud para una mascota que acaba de dejar de estar disponible. Duplicados, reintentos y orden de eventos. |
| **Infraestructura** | Ninguna (DA-03). | Bus de eventos en proceso como mínimo; broker si se separan procesos (viola DA-03). |
| **Efecto sobre TRX-02** | Ninguno: la consulta ocurre antes de los inserts y dentro de la misma transacción. | Ninguno sobre la atomicidad, pero la validación pasa a depender de una copia que puede estar desactualizada. |

### Alternativa que se ensaya primero: A

Patitas Urbanas decide **ensayar primero la alternativa A**. Esto no
significa que A sea "mejor" en general: es la hipótesis que el equipo
somete a prueba (§4), y la evidencia del spike puede refutarla.

Por qué se elige A para ensayar:

- Para solicitar una mascota se necesita su estado **en el momento** de la
  solicitud (D6: solo "Disponible" permite solicitar). Con B, Adopciones
  decidiría sobre una copia que puede estar desactualizada y aceptar una
  solicitud para una mascota que acaba de pasar a "En tratamiento" (D9) o
  a "Adoptada"; es el tipo de inconsistencia que QA-02 busca evitar.
- El costo principal de A, el acoplamiento temporal ("si Mascotas falla,
  Adopciones falla"), es pequeño en un monolito modular: ambos contextos
  viven en el mismo proceso y fallan juntos de todos modos.
- A no agrega infraestructura (DA-03); B exige al menos un bus de eventos,
  idempotencia y manejo de duplicados.

**Qué haría reconsiderar B:** que el spike muestre que la llamada síncrona
degrada la operación de forma medible (spike 2, Y6), o que Mascotas se despliegue
en un proceso separado.

### ¿Por qué A no es REST por HTTP?

En el ejemplo del curso, la alternativa síncrona es "REST síncrono": un
servicio consulta a otro por HTTP. En Patitas Urbanas los contextos son
módulos del **mismo proceso** (monolito modular, ADR-01), así que el
equivalente síncrono es una **llamada a la interfaz pública del otro módulo**
(`MascotaService`), con las mismas propiedades que importan para la
decisión: el consumidor espera la respuesta y obtiene el dato actual.

Usar HTTP entre módulos del mismo proceso añadiría red, serialización,
timeouts y nuevos modos de fallo sin ningún beneficio, y sacaría la consulta
de la transacción de TRX-02. REST se usa solo hacia los clientes externos
(`contrato-api.yaml`). **Si Mascotas se separa en otro proceso, la
alternativa A pasa a ser REST síncrono** y habría que volver a medir.

**Contrato propuesto entre módulos** (no implementado: hoy no existe
`Mascota`). Solo el estado "Disponible" permite solicitar
(`docs/dominio/modelo-dominio.md`, D6):

```java
// mascotas/MascotaService.java — API pública del contexto Mascotas
public DisponibilidadMascota consultarDisponibilidad(Long mascotaId);

// shared/dto/DisponibilidadMascota.java — DTO que cruza la frontera (ADR-02)
// disponible == true solo si estado es DISPONIBLE (D6); municipio para la regla D8
public record DisponibilidadMascota(Long mascotaId, boolean disponible, String estado, String municipio) {}
```

Lo que este contrato **no permite**: que Adopciones cambie la
disponibilidad, lea la entidad `Mascota` o use `MascotaRepository`
(regla de ADR-02, verificada por el medidor Y2 del spike).

---

## 2. Decisión para cada relación

| # | Relación | ¿El consumidor necesita el dato en el momento? | ¿Qué pasa si falla la otra parte? | Decisión | Revisar si… |
|---|---|---|---|---|---|
| R1 | Mascotas → Adopciones | Sí: solo se solicita una mascota en estado Disponible (D6) y del mismo municipio o área metropolitana (D8) | No se crea la solicitud (correcto) | **Síncrona en proceso** (alternativa que se ensaya, §4) | Mascotas se separa en otro proceso |
| R2 | Identidad → Adopciones | Sí: sin autorización de datos vigente no se puede escribir (QA-01, D5), y solo el custodio aprueba (D4) | No se crea la solicitud (correcto: exigido por QA-01) | **Síncrona en proceso** | Se adopta un proveedor de identidad externo (token firmado validable sin llamada) |
| R3 | Mascotas → Atención veterinaria | Sí: el historial clínico es de una mascota concreta, y "En tratamiento" debe bloquear solicitudes de inmediato (D9) | No se registra la atención ni el cambio de estado | **Síncrona en proceso** | Atención veterinaria necesita datos históricos que Mascotas no conserva |
| R4 | Adopciones → Notificaciones (consumidor futuro, fuera del modelo) | **No**: el aviso puede llegar segundos después | La solicitud sigue siendo válida; el aviso se reintenta | **Asíncrona (evento después del commit)** — aplazada hasta que exista un consumidor | Se definen reglas de negocio propias de notificación |
| R5 | Servicio de Mapas → Mascotas | Sí para la búsqueda | La búsqueda devuelve error controlado; no afecta a Adopciones | **Síncrona (HTTP externo) detrás de una ACL** | El proveedor tiene límites de uso que obliguen a cachear. La regla territorial (D8) no depende del proveedor |
| R6 | Identidad → Mascotas | Sí: el custodio debe ser un participante válido (D4) | No se registra o cambia la custodia | **Síncrona en proceso** | Se adopta un proveedor de identidad externo |
| R7 | Identidad → Atención veterinaria | Sí: solo un participante con rol de veterinaria registra historial clínico (D4) | No se registra la atención | **Síncrona en proceso** | Se adopta un proveedor de identidad externo |

R4 es la única relación donde lo asíncrono es mejor: avisar no es parte de
la regla de negocio y un fallo del proveedor externo no debe deshacer una
adopción (ver `dossier/17-cqrs-consistencia-eventual-s10.md`, §4).

---

## 3. Qué evidencia respalda la decisión

| Afirmación | Respaldo |
|---|---|
| La comunicación síncrona en proceso no agrega infraestructura | ADR-01 y ADR-03: un solo proceso y una base de datos; `docker-compose.yml` |
| TRX-02 necesita atomicidad | QA-02, `AdopcionControllerRollbackIntegrationTest` (pasa 3/3 en el spike) |
| Las fronteras entre módulos se respetan sin mecanismos nuevos | Spike 1: Y2 = 0, Y4 = 100%, Y5 = 0 (`experimentos/06-spike-resultado-s10.md`) |
| Hoy no existe ninguna llamada entre contextos | Código de `main`: `adopciones/` y `mascotas/` no se importan entre sí |
| Supuesto **no medido**: el costo de la llamada síncrona R1 es despreciable | No hay `MascotaService`; lo mide el spike 2 (`experimentos/08-spike-integracion-especificacion.md`, Y6) |

---

## 4. Cómo se pondrá a prueba: spike de integración propuesto

**Por qué hace falta un spike nuevo.** El spike 1 de Semana 10
(`experimentos/06-spike-resultado-s10.md`) puso a prueba las **fronteras
de los módulos** (ADR-01, ADR-02 y las Decisiones 1–2 de ADR-03). Su propio
veredicto aclara que **no evalúa la decisión de integración** (Decisión 3
de ADR-03), porque hoy no existe ninguna llamada entre contextos. Esta
sección plantea qué mediría un spike que valide o refute la alternativa A.

**Preregistro.** La hipótesis, las métricas, los umbrales y el protocolo
están fijados en
[`experimentos/08-spike-integracion-especificacion.md`](../../experimentos/08-spike-integracion-especificacion.md),
integrado a `main` antes de escribir código o medir. Resumen:

- **Regla que se pone a prueba:** D10. Una mascota puede tener varias
  solicitudes abiertas; al aprobar una, la mascota deja de estar Disponible
  y las demás se rechazan. Es el punto donde las alternativas A y B se
  diferencian: con 10 aprobaciones simultáneas, ¿la consulta síncrona evita
  que se apruebe más de una?
- **Condiciones:** A0 (A tal como está especificada) y A1 (A con bloqueo
  explícito de la fila de la mascota).
- **Métricas Y1–Y7:** aprobaciones por ráfaga, estado final coherente,
  atomicidad entre módulos, regla D6, fronteras (ADR-02), costo de la
  llamada síncrona y carga BIZ-01. La numeración vigente es la de la
  especificación.

El resultado se registrará en `experimentos/09-spike-integracion-resultado.md`
y actualizará esta decisión.

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 10 · Módulo 5 · Arquitectura de Software*
