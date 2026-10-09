# Responsabilidades de los bounded contexts
## Módulo 5 · Entregable 1 — Context Map justificado

Cada contexto declara **qué posee** (conceptos y datos de los que es el
único dueño) y **qué no posee**. La prueba aplicada a cada frontera es:
*"¿qué responsabilidad protege esta frontera y por qué no pertenece al
contexto vecino?"*

Las referencias RO1–RO6 (responsabilidades observables en el código),
D1–D9 (decisiones del equipo) y P1–P7 (preguntas) están en
[`modelo-dominio.md`](./modelo-dominio.md).

---

## 1. Contextos

### Adopciones — núcleo · implementado parcialmente

| | |
|---|---|
| **Responsabilidad** | Gestionar la solicitud de adopción de una mascota concreta, desde que se recibe hasta que se aprueba, rechaza o cancela. |
| **Posee** | **Implementado:** `SolicitudAdopcion` con el campo `estado` y valor inicial `PENDIENTE` (RO1); `EtapaAdopcion` inicial (RO2); la regla TRX-02 que las escribe juntas (RO3); tablas `solicitud_adopcion` y `etapa_adopcion`. **Definido por el equipo, no implementado:** el ciclo de estados Pendiente → Activa → Aprobada / Rechazada, y Cancelada (D1, D7); el historial de etapas (D1); el compromiso de adopción (D5); la regla territorial: adoptante y mascota en el mismo municipio o la misma área metropolitana (D8). |
| **No posee** | El estado y el ciclo de vida de la mascota (D3); la autorización de tratamiento de datos (D5); los datos personales del adoptante; el historial clínico. |
| **Por qué esta frontera** | La solicitud avanza por etapas sin que la mascota cambie (D1), y TRX-02 exige que solicitud y etapa se escriban en una sola transacción (QA-02, verificado por `AdopcionControllerRollbackIntegrationTest`). Mientras ambas vivan en el mismo contexto, la atomicidad no necesita coordinación entre contextos. |
| **Evidencia** | HECHO para solicitud, estado, etapa y TRX-02 (RO1–RO3). DECISIÓN para el historial de etapas, la referencia a la mascota y el compromiso (D1, D2, D5). |
| **Código** | `api/adopciones/` (`AdopcionController`, `AdopcionService`, repositorios, `model/`) |

### Mascotas — soporte · parcial

| | |
|---|---|
| **Responsabilidad** | Gestionar el ciclo de vida de cada animal bajo custodia. |
| **Posee** | `Mascota` (planificada), su estado (Disponible, Reservada, En tratamiento, Cuarentena, Extraviada, Adoptada…; D3, D6), su custodio (D4) y su ubicación (municipio y coordenadas para buscar, D8). |
| **No posee** | Las solicitudes de adopción ni sus etapas; el historial clínico; los datos personales del custodio. |
| **Por qué no pertenece a Adopciones** | La mascota cambia de estado aunque no haya ninguna solicitud (D3) y puede no ser adoptada nunca. Si Adopciones fuera dueña de `Mascota`, cada cambio de cuidado o custodia obligaría a tocar el núcleo. |
| **Evidencia** | DECISIÓN (D3, D4, D6, D8). En el código solo hay un endpoint simulado (RO4). |
| **Código** | `api/mascotas/MascotaController` (respuesta simulada). No existen `Mascota`, `MascotaService` ni `MascotaRepository`. |

### Atención veterinaria — soporte · planificado

| | |
|---|---|
| **Responsabilidad** | Registrar la información de salud de los animales. |
| **Posee** | Historial clínico, diagnóstico, tratamiento, certificado de salud (D4). |
| **No posee** | La aprobación o el rechazo de solicitudes; el estado de la mascota (puede pedir a Mascotas que la ponga "En tratamiento", D9, pero el estado lo registra Mascotas); los datos de la veterinaria como organización (son de Identidad). |
| **Por qué esta frontera** | La veterinaria certifica la salud pero no decide sobre la custodia ni la adopción (D4). La atención ocurre antes, durante y después de una adopción, y también para mascotas que nunca se adoptan. |
| **Evidencia** | DECISIÓN (D4, D9); sin código (RO5). |
| **Código** | Paquete `veterinarias/` declarado en ADR-01/ADR-03, sin clases. |

### Identidad — genérico · planificado

| | |
|---|---|
| **Responsabilidad** | Identidad de las personas y organizaciones que usan la plataforma, su rol y la autorización de tratamiento de datos (QA-01, Ley 1581). |
| **Posee** | Participante (adoptante, custodio —fundación o refugio—, veterinaria), rol, municipio del participante (D8), autorización de tratamiento de datos (D5), permisos. |
| **No posee** | El compromiso de adopción (D5); solicitudes; mascotas; historial clínico. |
| **Por qué esta frontera** | Concentra los datos personales en un solo contexto: es el único lugar donde hay que aplicar la auditoría y el consentimiento de la Ley 1581. Los demás contextos solo guardan identificadores. La autorización de datos aplica a toda la plataforma; el compromiso de adopción, solo a una solicitud (D5). |
| **Evidencia** | HECHO como driver (QA-01, RO6); DECISIÓN (D4, D5). |
| **Código** | No existe. |

---

## 2. Relaciones del Context Map

Cada relación indica quién depende de quién (**upstream** = proveedor,
**downstream** = consumidor), qué información fluye y cómo. La decisión
síncrona/asíncrona de cada una se justifica en
[`sincrono-vs-asincrono.md`](../integracion/sincrono-vs-asincrono.md).

| # | Relación | Patrón | Qué fluye y en qué dirección | Mecanismo | Estado |
|---|---|---|---|---|---|
| R1 | Mascotas → Adopciones | Cliente/Proveedor (Mascotas upstream) | Antes de crear la solicitud, Adopciones pregunta si la mascota está Disponible (D2, D6), quién es su custodio (D4) y en qué municipio está (D8). Cuando la adopción se aprueba o se concreta (el momento exacto está abierto, P8), Adopciones pide a Mascotas `marcarAdoptada(mascotaId)`; Mascotas cambia su propio estado (P5). Mascotas nunca lee solicitudes. | Síncrono en proceso: servicio público `MascotaService` (ADR-02, ADR-03 Decisión 3) | Planificada: hoy Adopciones no recibe `mascotaId` |
| R2 | Identidad → Adopciones | Cliente/Proveedor (Identidad upstream) | Adopciones pregunta si el adoptante tiene autorización de datos vigente (QA-01, D5), en qué municipio vive (D8) y si quien aprueba tiene rol de custodio (D4). Solo guarda identificadores. | Síncrono en proceso | Planificada |
| R3 | Mascotas → Atención veterinaria | Cliente/Proveedor (Mascotas upstream) | Atención veterinaria consulta la identidad y el estado de la mascota atendida. Si detecta una enfermedad, pide a Mascotas `marcarEnTratamiento(mascotaId)`; Mascotas cambia su propio estado y la mascota deja de poder solicitarse (D9). | Síncrono en proceso | Planificada |
| R4 | Adopciones → Notificaciones | Publicador/Suscriptor (Adopciones upstream) | Adopciones publica hechos como `SolicitudAdopcionAvanzoDeEtapa`; un futuro consumidor decide a quién avisar. **Notificaciones está fuera del modelo** (`modelo-dominio.md` §6): la relación se conserva solo como diseño del evento. | Asíncrono: evento después del commit ([`eventos-candidatos.md`](../integracion/eventos-candidatos.md)) | Aplazada (ADR-03, Alternativa B) |
| R5 | Servicio de Mapas → Mascotas | Capa anticorrupción (ACL) en Mascotas | Mascotas traduce coordenadas y distancias del proveedor externo a su propio modelo. Solo sirve para buscar; la regla territorial (D8) se valida con el municipio registrado de la mascota y del adoptante, no con el proveedor. | Llamada HTTP externa detrás de un adaptador | Planificada; hoy simulada |
| R6 | Identidad → Mascotas | Cliente/Proveedor (Identidad upstream) | Mascotas registra el custodio de cada animal como identificador de un participante con rol de custodio (D4). | Síncrono en proceso | Planificada |
| R7 | Identidad → Atención veterinaria | Cliente/Proveedor (Identidad upstream) | Atención veterinaria verifica que quien registra el historial clínico o pide "En tratamiento" es un participante con rol de veterinaria (D4, D9). | Síncrono en proceso | Planificada |

### Operaciones de cada relación

La flecha del Context Map va del **proveedor** (upstream, el contexto que
ofrece la operación en su API pública) al **consumidor** (downstream, el
que la invoca). No indica hacia dónde viaja la petición: en un **comando**
el consumidor pide un cambio que el proveedor decide y registra; en una
**consulta** el proveedor solo entrega datos.

| Relación | Operación (ofrecida por el proveedor) | Proveedor | Consumidor | Tipo | Qué viaja y hacia dónde |
|---|---|---|---|---|---|
| R1 | `consultarDisponibilidad(mascotaId)` | Mascotas | Adopciones | Consulta | Mascotas → Adopciones: estado, custodio, municipio |
| R1 | `marcarAdoptada(mascotaId)` | Mascotas | Adopciones | Comando | Adopciones → Mascotas: la petición; Mascotas cambia su propio estado |
| R2 | consultar participante (autorización de datos, rol, municipio) | Identidad | Adopciones | Consulta | Identidad → Adopciones |
| R3 | `consultarMascota(mascotaId)` | Mascotas | Atención veterinaria | Consulta | Mascotas → Atención veterinaria: identidad y estado de la mascota |
| R3 | `marcarEnTratamiento(mascotaId)` | Mascotas | Atención veterinaria | Comando | Atención veterinaria → Mascotas: la petición; Mascotas cambia su propio estado (D9) |
| R6 | consultar participante con rol de custodio | Identidad | Mascotas | Consulta | Identidad → Mascotas |
| R7 | consultar participante con rol de veterinaria | Identidad | Atención veterinaria | Consulta | Identidad → Atención veterinaria |

R1 y R3 tienen una consulta y un comando cada una, pero el proveedor es el
mismo (Mascotas): el estado de la mascota tiene un único dueño, y los demás
contextos solo pueden pedir que cambie. Por eso cada relación conserva una
sola flecha.

### Alcance de la atomicidad entre contextos

| | Qué garantiza | Respaldo |
|---|---|---|
| **Demostrado hoy** | Solicitud y etapa inicial se escriben juntas o no se escribe ninguna (TRX-02). Es una garantía **interna de Adopciones** | HECHO: `@Transactional` en `AdopcionService` y `AdopcionControllerRollbackIntegrationTest` (RO3) |
| **Propuesto, no implementado** | "En la misma transacción" (P5) significa **la misma transacción de base de datos**: `AdopcionService` abre la transacción y `MascotaService.marcarAdoptada` participa en ella (propagación por defecto de Spring). Si `marcarAdoptada` falla, también se revierte el cambio de la solicitud, así que no puede quedar una solicitud aprobada con la mascota Disponible | DECISIÓN técnica. Es posible porque ambos módulos comparten proceso y base de datos (ADR-01). Se verificaría con la métrica Y2 del spike de integración propuesto |

Esta garantía depende de que Mascotas siga en el mismo proceso. Si se
separa, deja de existir una transacción común y habría que usar otro
mecanismo (por ejemplo, una tabla outbox con compensación).

**Reglas que hacen cumplir estas relaciones** (ADR-02): ningún contexto
importa repositorios ni modelos de otro; solo servicios públicos o DTOs de
`shared/`. Verificado para Adopciones y Mascotas en el spike (Y2 = 0).

Ninguna de estas relaciones existe hoy en el código.

---

## 3. Diagrama

Fuente PlantUML: [`context-map.puml`](./context-map.puml)
([PNG](./context-map.png)). Versión Mermaid equivalente (se ve directamente
en GitHub):

```mermaid
flowchart LR
  subgraph CORE["Núcleo"]
    ADO["Adopciones<br/>(implementado parcialmente)"]
  end
  MAS["Mascotas<br/>(parcial)"]
  VET["Atención veterinaria<br/>(planificado)"]
  IDE["Identidad<br/>(planificado)"]
  NOT["Notificaciones<br/>(fuera del modelo)"]
  MAPS[("Servicio de Mapas<br/>externo")]

  MAS -- "R1 · U→D · consulta: ¿Disponible? / comando: marcarAdoptada<br/>síncrono en proceso" --> ADO
  IDE -- "R2 · U→D · autorización de datos · rol · municipio<br/>síncrono en proceso" --> ADO
  MAS -- "R3 · U→D · consulta: datos / comando: marcarEnTratamiento<br/>síncrono en proceso" --> VET
  IDE -- "R6 · U→D · custodio<br/>síncrono en proceso" --> MAS
  IDE -- "R7 · U→D · rol veterinaria<br/>síncrono en proceso" --> VET
  ADO -. "R4 · eventos después del commit<br/>(consumidor futuro)" .-> NOT
  MAPS -. "R5 · ACL en Mascotas" .-> MAS

  style NOT stroke-dasharray: 5 5
```

Flecha continua = relación síncrona; discontinua = asíncrona, externa o
fuera del modelo. La flecha va del proveedor (upstream) al consumidor
(downstream), aunque en los comandos la petición viaje en sentido contrario
(ver *Operaciones de cada relación*).

---

## 4. Prueba del Context Map aplicada

| Frontera | ¿Qué protege? | ¿Por qué no pertenece al vecino? |
|---|---|---|
| Adopciones / Mascotas | La atomicidad de TRX-02 y el proceso de la solicitud | La mascota cambia de estado sin solicitudes (D3); la solicitud avanza por etapas sin que la mascota cambie (D1) |
| Adopciones / Identidad | Los datos personales y la autorización de datos (Ley 1581) | La autorización aplica a toda la plataforma; el compromiso de adopción, solo a una solicitud (D5). Adopciones solo necesita saber si el participante está habilitado |
| Mascotas / Atención veterinaria | El ciclo de vida y la custodia de la mascota | La veterinaria certifica la salud y puede pausar la adopción por salud (D9), pero no decide sobre custodia ni adopción (D4); el estado lo registra Mascotas |
| Mascotas / Identidad | Los datos personales del custodio | Mascotas solo necesita saber quién es el custodio, no sus datos personales |
| Mascotas / Servicio de Mapas | El modelo propio de ubicación | El proveedor externo puede cambiar sin afectar al dominio |
| Adopciones / Notificaciones | La operación de adopción frente a fallos del proveedor externo | Avisar no es una regla de negocio: la solicitud es válida aunque el aviso falle |

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 10 · Módulo 5 · Arquitectura de Software*
