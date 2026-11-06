# Autoauditoría del Módulo 7 — Semanas 13 y 14 (2026-11-05)

Contrastada con la lista de verificación del tutor. La hizo la IA y **el equipo todavía no la ha revisado**. Estados: **Cumple**, **Parcial** y **Pendiente**.

**Alcance de la revisión:** el sílabo y el arco del proyecto no están en el repositorio (I-12). Solo se revisó contra la guía del tutor.

**Importante:** "Cumple" significa que el entregable existe en un pull request abierto. **Nada de esto está en `main` hasta que el equipo lo fusione.**

## 1. Lista de verificación del tutor

| # | Punto | Estado | Evidencia | Qué falta |
|---|---|---|---|---|
| 1 | Modelado de amenazas documentado | **Cumple** | `docs/10-seguridad.md` §1–§2: 18 amenazas, con activo, impacto y evidencia | Revisión del equipo |
| 2 | Matriz de riesgos de seguridad y controles | **Parcial** | `docs/10-seguridad.md` §4: 17 riesgos | Los tratamientos son propuestas: el equipo decide qué se acepta |
| 3 | Prueba de fuga reproducible y con resultados | **Cumple** | `experimentos/14-fuga-datos-s13/`: 13 sondas, 3 repeticiones, antes y después | — |
| 4 | Costo de seguridad sobre el p95, con condiciones | **Cumple** | `experimentos/15-costo-seguridad-s13/` | — |
| 5 | Evidencia del ciclo EDAV 3 formativo | **Parcial** | `docs/EDAV-03.md` | La auditoría humana y la firma son del equipo |
| 6 | Diagrama de despliegue | **Cumple** | `docs/12-despliegue-observabilidad.md` §1; `docs/despliegue/` | — |
| 7 | Comparación de costo relativo de alternativas | **Parcial** | `docs/12-despliegue-observabilidad.md` §2 | Elegir proveedor; el precio de V1 es de fuente secundaria y no hay COP |
| 8 | Plan de observabilidad: logs, métricas y trazas | **Cumple** | `docs/12-despliegue-observabilidad.md` §3 | Es un plan: las señales nuevas no están implementadas |
| 9 | Plan de monitoreo, alertas y recuperación | **Cumple** | Ídem §3.4 y §4 | Solo P-1 y P-2 están probados |
| 10 | Matriz de riesgos operativos | **Cumple** | `docs/13-riesgos-tradeoffs.md` §1: 14 riesgos | Revisión del equipo |
| 11 | ADR 5 documentado | **Parcial** | `adr/adr-05-seguridad-y-operacion.md`, estado **Propuesta** | Decisiones reales del equipo |
| 12 | Fitness function ejecutándose en CI | **Cumple** | FF-01 en `main` desde la Semana 12: `docs/fitness/ff-01-fronteras-modulares.md`, con ejecuciones actualizadas | FF-02 corre en su PR; pasa a `main` si se fusiona |
| 13 | Archivos organizados y enlazados desde el README | **Cumple** | README, sección "Módulo 7" | Se ve en `main` al fusionar |
| 14 | Evidencias técnicas guardadas en el repositorio | **Cumple** | `resultados/` de los experimentos 14, 15 y 16 | — |
| 15 | Cambios subidos mediante commits y pull requests | **Parcial** | PR #82, #83 y #84, en borrador | Revisar y fusionar |
| 16 | Cada integrante tiene contribuciones identificables | **Parcial** | Ambas cuentas aparecen en el historial, pero del 2026-10-24 al 2026-10-31 todos los commits de `main` son de Charry21, y los de esta semana son de la cuenta de Kevin | I-15: que cada uno revise o firme lo suyo |
| 17 | Decisiones y mediciones con fechas y referencias | **Cumple** | Cada experimento registra fecha, commit, entorno y corridas | — |

## 2. Revisión cruzada del tutor

| Pregunta | Respuesta |
|---|---|
| ¿Cada riesgo documentado tiene evidencia de dónde se identificó? | Sí. Las amenazas citan sonda, archivo o experimento; las hipotéticas están marcadas |
| ¿Las pruebas guardadas se pueden repetir? | Sí en lo técnico: scripts y comandos están versionados. Las mediciones usaron `Dockerfile.runtime` (F-08) |
| ¿El diagrama corresponde a los componentes reales? | La API y la BD sí. El proxy existe en el PR. El emisor de tokens y las copias se dibujan como inexistentes |
| ¿El plan de observabilidad se relaciona con escenarios concretos? | Sí: cada señal cita F-xx o T-xx |
| ¿El ADR 5 registra decisiones reales del equipo? | **Todavía no.** Es una propuesta de la IA, con una tabla para que el equipo decida |
| ¿La fitness function se puede ver ejecutándose en CI? | Sí: pestaña Actions, workflow `fitness-functions` |

## 3. Novedades e inconsistencias encontradas

| # | Severidad | Inconsistencia | Dónde | Qué se hizo | Quién decide |
|---|---|---|---|---|---|
| I-01 | **Alta** | La condición del ADR-04 (R-10) vencía al cierre de la Semana 13 y `main` sigue sin `restart:` | `dossier/evidencia-comite-adr04.md`, `docker-compose.yml` | Implementada y probada en el PR, sin fusionar | Equipo: fusionar y dar por cumplida la condición |
| I-02 | **Alta** | El plan M6-3 pone R-10 primero y R-11 cuarta, pero R-10 sola borra los datos en cada caída | `docs/registro-ia-modulo6.md`, exp. 16 HR2 | R-10 y R-11 van juntas en el PR | Equipo: cambiar el orden |
| I-03 | **Alta** | El escenario 2 y QA-01 son prioridad alta y nunca se implementaron | `dossier/04-escenarios-calidad.md`, `dossier/02` | Capa candidata en el PR | Equipo, en ADR-05 |
| I-04 | **Alta** | `dossier/02` pide la BD en red privada (R-05), y `docker-compose.yml` la publica con una contraseña versionada. ADR-04 afirma que D1 no abre canales nuevos | P07 | Corregido en el PR | Equipo |
| I-05 | Media | El C4 dice `JSON/HTTPS`, pero la API es HTTP en claro | `dossier/06-c4-contenedores.md`, P11 | Sin cambiar: es un documento auditado | Equipo |
| I-06 | Media | ADR-01 habla de "un único punto de autenticación", que no existe | `adr/adr-01-decision-estilo.md` | Sin cambiar | Equipo |
| I-07 | Media | `R-xx` significa cosas distintas: tácticas (`docs/resiliencia`), riesgos (`dossier/02` y `dossier/04-riesgos.md`, con listas diferentes), relaciones R1–R5 y reglas de FF-01 | Varios | Se usaron `RS`, `RO` y `TO` | Equipo |
| I-08 | Media | R-06 figuraba como **Probada** ("nunca 500") y una entrada de 300 caracteres da 500 | `docs/resiliencia/matriz-resiliencia.md` | Pasada a **Parcial**; añadido F-14; corregida en el PR | Equipo: validar el cambio |
| I-09 | Media | ADR-04 y A4 miden el margen del escenario 1 (búsqueda) con el p95 de **escritura**, porque `/buscar` es simulado. No hay evidencia de una búsqueda real | `adr/adr-04-distribucion.md`, `docs/distribucion/` | Registrado como RO-12 | Equipo |
| I-10 | Media | El README decía que los datos se conservan en el volumen, pero `create-drop` los borra al reiniciar la API | `README.md`, F-13 | Corregido en el PR | Equipo |
| I-11 | Media | `QA-03` y `BIZ-01` significan cosas distintas en `dossier/02` y en `dossier/04`, y QA-02 sigue como "no medido" aunque hay evidencia | `dossier/02`, `dossier/04` | Sin cambiar | Equipo |
| I-12 | Media | El sílabo y el arco del proyecto no están en el repositorio, y la guía del tutor los cita | — | Solo se revisó contra la guía | Equipo: contrastar con la rúbrica |
| I-13 | Media | CI no ejecuta las pruebas: el test de rollback (QA-02) solo corre a mano | `.github/workflows/` | Registrado como RO-11 | Equipo |
| I-14 | Baja | Calendario: la guía pone las semanas 13–14 en el Módulo 7, y el README titula "Módulo 6 (Semanas 11–14)" | `README.md` | Sección nueva "Módulo 7"; el título anterior no se cambia | Equipo |
| I-15 | Baja | Del 2026-10-24 al 2026-10-31 no hay commits de la cuenta de Kevin en `main`, aunque esos documentos llevan los dos nombres | `git log` | Se anota; no es un error, pero el tutor pide contribuciones identificables | Equipo |
| I-16 | Baja | Las rutas sugeridas no coinciden con las del repositorio: `docs/ADR-05.md` frente a `adr/`, `experimentos/seguridad/` frente a la numeración. Tampoco existe `docs/11-*`, y `dossier/10`, `12` y `13` tratan otros temas | — | Se siguieron las convenciones del repositorio, como permite la guía | Equipo: confirmar con el tutor |

## 4. Pendientes que dependen del equipo

1. Revisar y fusionar los PR en este orden: #82, #83 y #84.
2. Decidir ADR-05, incluido el emisor de tokens, y si necesita mini-comité.
3. Completar la EDAV 3 y firmar el registro de IA.
4. Probar el README en un computador del equipo con Windows. En Linux ya pasó, en una máquina limpia (`docs/verificacion/arranque-limpio-2026-11-06/`): lo ejecutó la IA a pedido del equipo.
5. Implementar lo que quedó solo propuesto: copias, alertas, R-09 y R-08.
6. Contrastar esta auditoría con la rúbrica.

Revisado por: *pendiente* · Fecha: *pendiente*
