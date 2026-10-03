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

| | Alternativa A — Síncrona en proceso | Alternativa B — Eventos asíncronos |
|---|---|---|
| **Mecanismo** | `AdopcionService` llama a `MascotaService.consultarDisponibilidad(mascotaId)` antes de crear la solicitud, dentro del mismo proceso. | Mascotas publica `MascotaDisponibilidadCambiada`; Adopciones guarda una copia local de la disponibilidad y la consulta. |
| **Ventaja** | El dato es el actual en el momento de la solicitud; no hay copia que sincronizar. La validación ocurre dentro de la transacción de TRX-02. | Adopciones no depende de que Mascotas responda en ese instante. |
| **Costo / riesgo** | Acoplamiento temporal: si `MascotaService` falla, la solicitud falla. En un monolito este riesgo es bajo: es una llamada a un método en el mismo proceso, sin red. | Copia replicada y consistencia eventual: se podría aceptar una solicitud para una mascota que acaba de dejar de estar disponible. Duplicados, reintentos y orden de eventos. |
| **Infraestructura** | Ninguna (DA-03). | Bus de eventos en proceso como mínimo; broker si se separan procesos (viola DA-03). |
| **Efecto sobre TRX-02** | Ninguno: la consulta ocurre antes de los inserts y dentro de la misma transacción. | Ninguno sobre la atomicidad, pero la validación pasa a depender de una copia que puede estar desactualizada. |

**Decisión: A — síncrona en proceso.** Para adoptar una mascota se
necesita su disponibilidad **en el momento** de la solicitud; aceptar un
dato desactualizado implica asignar dos veces la misma mascota, que es
justo el tipo de inconsistencia que QA-02 prohíbe. El costo de A (acoplamiento
temporal) casi desaparece en un monolito modular.

**Contrato propuesto entre módulos** (no implementado: hoy no existe
`Mascota`):

```java
// mascotas/MascotaService.java — API pública del contexto Mascotas
public DisponibilidadMascota consultarDisponibilidad(Long mascotaId);

// shared/dto/DisponibilidadMascota.java — DTO que cruza la frontera (ADR-02)
public record DisponibilidadMascota(Long mascotaId, boolean disponible, String estado) {}
```

Lo que este contrato **no permite**: que Adopciones cambie la
disponibilidad, lea la entidad `Mascota` o use `MascotaRepository`
(regla de ADR-02, verificada por el medidor Y2 del spike).

---

## 2. Decisión para cada relación

| # | Relación | ¿El consumidor necesita el dato en el momento? | ¿Qué pasa si falla la otra parte? | Decisión | Revisar si… |
|---|---|---|---|---|---|
| R1 | Mascotas → Adopciones | Sí: no se puede adoptar una mascota no disponible | No se crea la solicitud (correcto) | **Síncrona en proceso** | Mascotas se separa en otro proceso |
| R2 | Identidad → Adopciones | Sí: sin Opt-In no se puede escribir (QA-01) | No se crea la solicitud (correcto: exigido por QA-01) | **Síncrona en proceso** | Se adopta un proveedor de identidad externo (token firmado validable sin llamada) |
| R3 | Mascotas → Veterinarias | Sí: la cita es sobre una mascota concreta | No se agenda la cita | **Síncrona en proceso** | Veterinarias necesita datos históricos que Mascotas no conserva |
| R4 | Adopciones → Notificaciones | **No**: el aviso puede llegar segundos después | La solicitud sigue siendo válida; el aviso se reintenta | **Asíncrona (evento después del commit)** — aplazada hasta que exista Notificaciones | — |
| R5 | Servicio de Mapas → Mascotas | Sí para la búsqueda | La búsqueda devuelve error controlado; no afecta a Adopciones | **Síncrona (HTTP externo) detrás de una ACL** | El proveedor tiene límites de uso que obliguen a cachear |

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
| Supuesto **no medido**: el costo de la llamada síncrona R1 es despreciable | No hay `MascotaService`; se medirá cuando se implemente R1 |

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 10 · Módulo 5 · Arquitectura de Software*
