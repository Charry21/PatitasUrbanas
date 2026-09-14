# Evidencia de Uso y Crítica de IA · Semana 7
## Patitas Urbanas · Módulo 4

---

## 1. Propósito de este documento

Registrar el ciclo completo de delegación a IA y auditoría humana
para la Semana 7, dejando trazabilidad del uso, las sugerencias
aceptadas, las modificadas y las rechazadas, con sus razones.
Este documento cumple el requisito del Módulo 4 de criticar
explícitamente la propuesta arquitectónica generada por IA.

---

## 2. Herramienta utilizada

| Campo | Valor |
|---|---|
| Herramienta | Claude (Anthropic) — claude.ai |
| Modelo | Claude Sonnet 4.6 |
| Fecha de interacción | 2026-09-13 |
| Modalidad | Conversación iterativa con lectura directa del repositorio |

---

## 3. Contexto de la delegación

El equipo proporcionó al agente acceso de lectura al repositorio
público `Charry21/PatitasUrbanas` mediante URLs directas a los
archivos. El agente leyó los siguientes artefactos:

- `dossier/06-c4-contenedores.md` — contenido del C4 Nivel 2
- `dossier/07-c4-componentes.md` — contenido del C4 Nivel 3
- `experimentos/resultado-corrida-1.txt` a `resultado-corrida-4.txt`
- `experimentos/resultado-linea-base.txt`
- PR #41 (diff de `AdopcionController.java`)
- Issues #19, #20, #21

El agente también recibió como contexto el documento del tutor con
los requerimientos de Semana 7 y la ficha de entregables del curso.

---

## 4. Solicitudes realizadas y respuestas del agente

### Solicitud 1 — Identificación de servicios y arquitectura

**Prompt resumido:** el equipo solicitó al agente que identificara
los servicios necesarios para el proyecto según los tipos de datos
de la base de datos y el negocio.

**Respuesta del agente:** propuso una arquitectura de 6 librerías,
12 DAOs y 10 servicios de transacción diseñados para Firestore/NoSQL,
incluyendo `FirebaseLib`, `GeoLib`, `StorageLib`, `NotificacionLib`,
DAOs para cada colección de Firestore y servicios como
`AdopcionService`, `VeterinariaService`, `ChatService`, entre otros.

### Solicitud 2 — Nuevas colecciones y servicios V2.0

**Prompt resumido:** el equipo solicitó ampliar el diseño con nuevas
colecciones y servicios para mejorar el proyecto.

**Respuesta del agente:** propuso 6 colecciones nuevas
(`notificaciones`, `historial_medico`, `chat_mensajes`,
`reportes_moderacion`, `verificacion_entidades`, `gamificacion`),
4 DAOs adicionales y 5 servicios de transacción nuevos, totalizando
39 componentes de arquitectura.

### Solicitud 3 — Análisis de Semana 7

**Prompt resumido:** el equipo presentó la ficha de Semana 7 y
solicitó orientación para producir los entregables.

**Respuesta del agente:** leyó el repositorio, identificó la
limitación metodológica del endpoint simulado, detectó la
inconsistencia de terminología en el C4 ("Microservicio" vs monolito
real), propuso tres alternativas arquitectónicas contextualizadas
al sistema real y advirtió que su propuesta previa de 39 componentes
no aplicaba al stack real del repositorio.

---

## 5. Sugerencias aceptadas

| Sugerencia del agente | Razón de aceptación |
|---|---|
| Identificar la tensión como de mantenibilidad, no de rendimiento | Está respaldada por la evidencia de las corridas K6 y las hipótesis refutadas de S6 |
| Seleccionar monolito modular como alternativa provisional | Es proporcional al equipo, al plazo y al stack existente |
| Corregir la terminología "Microservicio" del C4 a "Monolito en capas" | El repositorio confirma que es un único contenedor desplegable |
| Declarar explícitamente que las corridas 1–3 fueron contra endpoint simulado | Está documentado en el código y en los Issues #19 y #21 |
| Estructurar los entregables en dossier/, docs/ y adr/ según el tutor | Corresponde a la ficha del curso confirmada por el tutor |
| Identificar la corrida 4 como posible primer comportamiento real con JPA | El cambio en p(95) y los dropped iterations son observables y verificables |

---

## 6. Sugerencias modificadas

| Sugerencia original del agente | Modificación aplicada | Razón |
|---|---|---|
| Producir un único archivo `08-decision-estilo-arquitectonico.md` con todo el contenido | Se dividió en 5 archivos de dossier + 1 en docs + 2 en adr | El tutor especificó que dossier, docs y adr tienen propósitos distintos y no deben mezclarse |
| Incluir a "Andrea Carolina Palomino Sáenz" como autora | Se corrigió a "Charry Ríos Daniel Estiven" | El agente asumió un nombre incorrecto no proporcionado por el equipo |
| Proponer microservicios como una de las alternativas a comparar en detalle | Se mantuvo como alternativa descartada sin análisis detallado | No hay ningún driver activo que justifique microservicios para el contexto actual |

---

## 7. Sugerencias rechazadas

| Sugerencia del agente | Razón de rechazo |
|---|---|
| Arquitectura de 6 librerías + 12 DAOs + 10 servicios de transacción para Firestore | El stack real del repositorio es Spring Boot + PostgreSQL, no Firestore. La propuesta no aplicaba al sistema existente. |
| 6 colecciones nuevas de Firestore (notificaciones, historial médico, chat, etc.) | El sistema usa PostgreSQL con JPA, no Firestore. Las colecciones propuestas corresponden a un modelo de datos diferente al implementado. |
| 39 componentes de arquitectura en total | Es sobreingeniería para un equipo de 2 personas con plazo fijo. No existe evidencia que justifique esa cantidad de componentes. |
| Arquitectura hexagonal como decisión inmediata | El costo de implementación es desproporcionado para el plazo disponible. No hay evidencia de que la independencia tecnológica sea un driver prioritario ahora. |

---

## 8. Supuestos falsos identificados en las propuestas del agente

**SF-01 — Stack incorrecto:**
El agente asumió inicialmente que el sistema usaba Firestore/NoSQL
para proponer DAOs y librerías. El repositorio evidencia claramente
que el stack es Spring Boot + PostgreSQL 16 con JPA. La propuesta de
39 componentes estaba diseñada para un sistema que no existe.

**SF-02 — Escala del equipo:**
El agente propuso una arquitectura que implica mantener 39 componentes
sin considerar que el equipo es de 2 personas con plazo universitario
fijo. La propuesta asumía implícitamente un equipo mayor o una fase
de implementación más larga.

**SF-03 — Evidencia de rendimiento:**
En iteraciones anteriores de la conversación, el agente trató las
corridas K6 como evidencia de rendimiento real del sistema. La
limitación del endpoint simulado solo fue declarada explícitamente
cuando se leyeron los Issues #19 y #21. Las conclusiones previas
basadas en esas corridas deben tratarse con cautela.

**SF-04 — Nombre de autora incorrecto:**
El agente incluyó el nombre "Andrea Carolina Palomino Sáenz" como
autora del documento sin que el equipo lo hubiera proporcionado.
Fue una inferencia incorrecta que el equipo detectó y corrigió.

---

## 9. Riesgos omitidos en las propuestas del agente

**RO-01 — Costo de reescritura no declarado:**
La propuesta de 39 componentes no mencionó explícitamente el costo
de migrar el sistema existente a esa estructura. Para el plazo
disponible, ese costo habría consumido el tiempo de experimentación
y documentación requerido por el curso.

**RO-02 — Incompatibilidad con la evidencia disponible:**
El agente propuso decisiones arquitectónicas antes de leer el
repositorio completo. Algunas sugerencias iniciales no estaban
ancladas en el código real sino en el documento PDF del proyecto,
que describe el sistema deseado, no el implementado.

**RO-03 — Reversibilidad no evaluada:**
Las propuestas iniciales (arquitectura hexagonal, 39 componentes)
no evaluaron la dificultad de revertir la decisión si no funcionaba.
La reversibilidad es un criterio explícito del curso.

---

## 10. Decisión humana que permaneció al final

Tras la auditoría de las propuestas del agente, el equipo tomó las
siguientes decisiones propias:

1. **Adoptar monolito modular** como estilo provisional, no por
   recomendación directa del agente sino porque la evidencia del
   repositorio (PRs #22 y #41) confirma que el dominio de adopciones
   ya está naturalmente cohesionado y la reorganización formaliza
   lo que el código sugiere.

2. **Rechazar las propuestas de Firestore** porque no corresponden
   al sistema implementado.

3. **Dividir los entregables** según la estructura indicada por el
   tutor, no según la estructura propuesta inicialmente por el agente.

4. **Mantener las incertidumbres declaradas** en lugar de presentar
   una decisión como confirmada cuando el mini-comité aún no se ha
   realizado.

---

## 11. Verificación de la crítica

Las afirmaciones de este documento están verificables mediante:

- El historial de la conversación con el agente (2026-09-13)
- Los archivos del repositorio referenciados en cada sección
- Los Issues #19, #20 y #21 que documentan las limitaciones metodológicas
- Los PRs mergeados que confirman el stack real del sistema

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Fecha: 2026-09-13*
*Semana 7 · Módulo 4 · Arquitectura de Software*
