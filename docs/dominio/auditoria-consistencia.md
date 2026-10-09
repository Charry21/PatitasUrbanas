# Seguimiento de la auditoría de consistencia interna
## Módulo 5 · Entregable 1

El tutor auditó la consistencia entre `modelo-dominio.md`,
`responsabilidades-contextos.md` y `subdominios.md` (2026-10-09) y registró
los hallazgos H1–H7. Este documento lleva el estado de cada uno.

Criterio aplicado, tomado de la auditoría: cuando un hallazgo exige una
regla de negocio nueva, **no se resuelve en la documentación**; se registra
como pregunta abierta para que la decida el equipo.

---

## Estado de los hallazgos

| # | Hallazgo | Tipo | Estado | Qué se cambió |
|---|---|---|---|---|
| H1 | R3 mezcla la dirección de la consulta con la del comando | Redacción | **Atendido** | Nueva tabla *Operaciones de cada relación* en `responsabilidades-contextos.md` §2: cada operación con proveedor, consumidor, tipo (consulta o comando) y hacia dónde viaja. La leyenda del diagrama explica que la flecha va del proveedor al consumidor |
| H2 | No está explícita la relación entre Aprobada, etapa final y adopción concretada | Regla de negocio | **Abierto → P8** | Se registró P8. P5 queda "resuelta en parte". Con D10 (2026-10-09) ya se sabe que la mascota deja de estar Disponible al aprobar; falta decidir si pasa a Reservada o Adoptada |
| H3 | El estado de la solicitud se presenta como más implementado de lo que demuestra el código | Redacción | **Atendido** | Glosario, tabla de contextos, `Posee` de Adopciones y context map separan lo implementado (campo `estado`, valor `PENDIENTE`, etapa inicial, TRX-02) de lo definido en D1–D8 |
| H4 | La regla territorial tiene dos formulaciones | Redacción + regla de negocio | **Redacción atendida; definición abierta → P10** | Frase canónica en D8 ("mismo municipio o misma área metropolitana") usada en todos los documentos de dominio. Qué cuenta como área metropolitana queda en P10. La misma corrección en `sincrono-vs-asincrono.md` se aplica en el PR del Entregable 2 para evitar conflictos |
| H5 | "En la misma transacción" no precisa el alcance de la atomicidad | Redacción técnica | **Atendido** | Nueva sección *Alcance de la atomicidad entre contextos*: lo demostrado (TRX-02, interno de Adopciones) separado de lo propuesto (transacción de base de datos compartida con `retirarDeDisponibles`, que pone a prueba el spike de integración) |
| H6 | Custodio, fundación, refugio y veterinaria no tienen el mismo nivel de precisión | Regla de negocio | **Abierto → P9** | Se registró P9 y se marcó en el glosario |
| H7 | La clasificación de subdominios mezcla importancia de negocio con evidencia técnica | Redacción | **Atendido; razones por validar** | La tabla de `subdominios.md` separa *razones de negocio* de *estado en el código*; la razón del núcleo ya no menciona TRX-02 implementada. El equipo debe confirmar que esas razones son las suyas (pregunta 7 del tutor) |

---

## Preguntas del tutor y dónde se responden

| # | Pregunta | Respuesta |
|---|---|---|
| 1 | ¿Qué diferencia exacta hay entre una solicitud aprobada y una adopción concretada? | Pendiente del equipo (P8) |
| 2 | ¿Qué operaciones ofrece Mascotas a Atención veterinaria y en qué dirección fluye cada una? | `responsabilidades-contextos.md` §2, *Operaciones de cada relación* (R3) |
| 3 | ¿Qué garantía significa "en la misma transacción"? | `responsabilidades-contextos.md` §2, *Alcance de la atomicidad entre contextos* |
| 4 | ¿La regla territorial permite municipios distintos de la misma área metropolitana? | Según la redacción de D8, sí; qué cuenta como área metropolitana está pendiente (P10) |
| 5 | ¿Qué parte del ciclo de vida de la solicitud está implementada? | Solo el campo `estado` con valor inicial `PENDIENTE` y la etapa inicial (RO1–RO3). El ciclo completo es D1 y D7 |
| 6 | ¿"Veterinaria" es persona, organización o rol? ¿Quién recibe los permisos? | Pendiente del equipo (P9) |
| 7 | ¿Qué razones de negocio sostienen la clasificación de subdominios? | `subdominios.md` §2, columna *Razones de negocio*; pendiente de confirmación del equipo |

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Módulo 5 · Arquitectura de Software*
