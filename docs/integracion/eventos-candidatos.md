# Eventos de dominio candidatos
## Módulo 5 · Entregable 4 — Diseño mediante eventos

Un **evento de dominio** es un hecho ya ocurrido que otro contexto necesita
conocer para actualizar su estado o tomar una decisión. Una **API** es una
pregunta que el consumidor hace cuando la necesita. Este catálogo filtra los
candidatos con tres preguntas:

1. ¿Es un **hecho del negocio** (no una acción de interfaz ni una operación técnica)?
2. ¿Hay **otro contexto** que necesite enterarse?
3. ¿Ese contexto puede enterarse **después** sin romper una regla (QA-02, QA-01)?

Solo si las tres respuestas son "sí" el candidato se acepta como evento.

**Estado actual:** el sistema **no publica ningún evento**. Este catálogo
es de diseño; se implementa cuando exista el contexto consumidor
(ADR-03, Decisión 3, Alternativa B aplazada).

**Sobre Notificaciones:** el modelo del dominio
(`docs/dominio/modelo-dominio.md` §6) deja Notificaciones **fuera del
modelo**: no tiene reglas de negocio propias ni código. Aquí aparece solo
como **consumidor futuro** de los eventos. Los eventos siguen siendo
válidos porque los publican contextos del modelo (Adopciones, Identidad).

---

## 1. Candidatos aceptados

| Evento | Contexto que lo publica | Cuándo ocurre | Quién lo consume y para qué | Datos mínimos |
|---|---|---|---|---|
| `SolicitudAdopcionCreada` | Adopciones | Después del commit de TRX-02 (solicitud + etapa inicial) | Notificaciones (futuro): avisar al custodio (fundación o refugio, D4) que hay una nueva solicitud | `idSolicitud`, `mascotaId`, `adoptanteId`, fecha |
| `SolicitudAdopcionAvanzoDeEtapa` | Adopciones | Después del commit que registra una nueva `EtapaAdopcion` | Notificaciones (futuro): avisar al adoptante del cambio | `idSolicitud`, etapa anterior, etapa nueva, fecha |
| `AdopcionConcretada` | Adopciones | La solicitud llega a la etapa final aprobada | Notificaciones (futuro): confirmar a adoptante y custodio | `idSolicitud`, `mascotaId`, `adoptanteId`, fecha |
| `ConsentimientoRevocado` | Identidad | El participante retira su autorización de tratamiento de datos (Ley 1581, D5) | Notificaciones (futuro): dejar de enviarle mensajes. Adopciones: marcar sus solicitudes abiertas para revisión | `usuarioId`, fecha |

Todos cumplen las tres preguntas: son hechos del dominio, tienen un
consumidor concreto y el consumidor puede enterarse segundos después sin
romper ninguna regla.

**Datos mínimos (Ley 1581):** los eventos llevan identificadores, no datos
personales. Notificaciones obtiene el contacto del usuario preguntando a
Identidad, que es el único contexto que custodia esos datos.

---

## 2. Candidatos que NO se convierten en evento

| Candidato | Por qué se rechaza | Qué se hace en su lugar |
|---|---|---|
| `BotonBuscarMascotaPresionado` | Es una interacción de interfaz, no un hecho del dominio. Ningún contexto necesita saberlo. | Nada. Si se quiere analítica de uso, es un problema de la interfaz. |
| `BusquedaGeoespacialRealizada` | Es una consulta: no cambia el estado de nada. | Nada. |
| `SolicitudConsultada` | Lectura, no un hecho que cambie el dominio. | Nada. |
| `FilaInsertadaEnSolicitudAdopcion` / `EtapaAdopcionInsertada` | Son operaciones CRUD técnicas que duplican `SolicitudAdopcionCreada` con vocabulario de base de datos. | Se usa `SolicitudAdopcionCreada`. |
| `FalloSimuladoEjecutado` (`/api/adopciones/test-fallo`) | Es un artefacto de prueba de QA-02, no un hecho del negocio. | Nada. |
| `MascotaActualizada` | CRUD genérico: no dice qué cambió ni por qué le importa a otro contexto. | Si un cambio concreto importa, se nombra el hecho (por ejemplo, `MascotaRetiradaDelCatalogo`). |
| `MascotaDisponibilidadCambiada` **para que Adopciones valide la solicitud** | Falla la pregunta 3: si Adopciones usara una copia desactualizada podría aceptar dos solicitudes para la misma mascota (QA-02). | Consulta síncrona R1 (`docs/integracion/sincrono-vs-asincrono.md`). Puede reconsiderarse como evento solo para un catálogo de lectura (ver `cqrs-event-sourcing.md`). |
| Marcar la mascota como adoptada en Mascotas mediante `AdopcionConcretada` | Falla la pregunta 3: mientras el evento no llegue, la mascota seguiría disponible y podría solicitarse de nuevo. | Llamada síncrona en proceso `MascotaService.marcarAdoptada(mascotaId)` dentro de la misma transacción que concreta la adopción. `AdopcionConcretada` se publica después solo para Notificaciones. |

---

## 3. Reglas de publicación (cuando se implemente)

- Publicar **solo después del commit** de la transacción que produjo el hecho
  (por ejemplo, evento de Spring con `@TransactionalEventListener(phase = AFTER_COMMIT)`
  o tabla outbox). Nunca dentro de TRX-02.
- Los consumidores deben ser **idempotentes**: recibir dos veces el mismo
  evento no debe enviar dos avisos (clave: identificador del evento).
- Fallos registrados y reintentables; una solicitud nunca se revierte porque
  falle un consumidor.
- Si el envío sale del proceso, aplica la condición del mini-comité de
  Semana 8 (cifrado en tránsito y autenticación).

---

## 4. Referencias

- `docs/dominio/responsabilidades-contextos.md` (relación R4)
- `docs/integracion/sincrono-vs-asincrono.md`
- `adr/adr-03-limites-y-comunicacion-modulos.md` (Decisión 3)
- `dossier/17-cqrs-consistencia-eventual-s10.md`

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 10 · Módulo 5 · Arquitectura de Software*
