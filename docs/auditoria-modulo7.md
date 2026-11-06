# Autoauditoría del Módulo 7 — Semanas 13 y 14 (2026-11-05)

Contrastada con la lista de verificación del tutor. La hizo la IA y la revisó el equipo (Kevin Torres · Daniel Charry) el 2026-11-06. Estados: **Cumple**, **Parcial** y **Pendiente**.

**Alcance de la revisión:** el sílabo y el arco del proyecto no están en el repositorio (I-12). Solo se revisó contra la guía del tutor.

**Estado (actualizado el 2026-11-06):** todos los PR del módulo están fusionados en `main` (inventario en §5), así que "Cumple" significa que el entregable está en `main`.

## 1. Lista de verificación del tutor

| # | Punto | Estado | Evidencia | Qué falta |
|---|---|---|---|---|
| 1 | Modelado de amenazas documentado | **Cumple** | `docs/10-seguridad.md` §1–§2: 18 amenazas, con activo, impacto y evidencia | Revisión del equipo |
| 2 | Matriz de riesgos de seguridad y controles | **Cumple** | `docs/10-seguridad.md` §4: 17 riesgos, calificados por el equipo (`docs/verificacion/revision-manual-s6-2026-11-06/`) | — |
| 3 | Prueba de fuga reproducible y con resultados | **Cumple** | `experimentos/14-fuga-datos-s13/`: 13 sondas, 3 repeticiones, antes y después | — |
| 4 | Costo de seguridad sobre el p95, con condiciones | **Cumple** | `experimentos/15-costo-seguridad-s13/` | — |
| 5 | Evidencia del ciclo EDAV 3 formativo | **Cumple** | `docs/EDAV-03.md` | Auditada y firmada el 2026-11-06 |
| 6 | Diagrama de despliegue | **Cumple** | `docs/12-despliegue-observabilidad.md` §1; `docs/despliegue/` | — |
| 7 | Comparación de costo relativo de alternativas | **Parcial** | `docs/12-despliegue-observabilidad.md` §2 | Elegir proveedor; el precio de V1 es de fuente secundaria y no hay COP |
| 8 | Plan de observabilidad: logs, métricas y trazas | **Cumple** | `docs/12-despliegue-observabilidad.md` §3 | Es un plan: las señales nuevas no están implementadas |
| 9 | Plan de monitoreo, alertas y recuperación | **Cumple** | Ídem §3.4 y §4 | Solo P-1 y P-2 están probados |
| 10 | Matriz de riesgos operativos | **Cumple** | `docs/13-riesgos-tradeoffs.md` §1: 14 riesgos | Revisión del equipo |
| 11 | ADR 5 documentado | **Cumple** | `adr/adr-05-seguridad-y-operacion.md`, aceptada por el equipo el 2026-11-06, con el emisor aplazado | Ninguno: el sílabo no asigna mini-comité a ADR-05 (tutor, 2026-11-06) |
| 12 | Fitness function ejecutándose en CI | **Cumple** | FF-01 en `main` desde la Semana 12 y FF-02 desde el PR #83 (2026-11-06), las dos en el workflow `fitness-functions` con su prueba negativa | — |
| 13 | Archivos organizados y enlazados desde el README | **Cumple** | README, sección "Módulo 7" | — |
| 14 | Evidencias técnicas guardadas en el repositorio | **Cumple** | `resultados/` de los experimentos 14, 15 y 16 | — |
| 15 | Cambios subidos mediante commits y pull requests | **Cumple** | Un PR por actividad, revisados y fusionados por el equipo (inventario en §5) | — |
| 16 | Cada integrante tiene contribuciones identificables | **Parcial** | Commits de las dos cuentas; Daniel Charry fusionó el PR #84 y Kevin Torres los demás (inventario en §5). La reescritura de `main` del 2026-11-06 está documentada en `experimentos/07-trazabilidad-temporal.md` | I-15: cada uno debe poder explicar lo que revisó y decidió |
| 17 | Decisiones y mediciones con fechas y referencias | **Cumple** | Cada experimento registra fecha, commit, entorno y corridas | — |

## 2. Revisión cruzada del tutor

| Pregunta | Respuesta |
|---|---|
| ¿Cada riesgo documentado tiene evidencia de dónde se identificó? | Sí. Las amenazas citan sonda, archivo o experimento; las hipotéticas están marcadas |
| ¿Las pruebas guardadas se pueden repetir? | Sí en lo técnico: scripts y comandos están versionados. Las mediciones usaron `Dockerfile.runtime` (F-08) |
| ¿El diagrama corresponde a los componentes reales? | La API y la BD sí. El proxy existe en el PR. El emisor de tokens y las copias se dibujan como inexistentes |
| ¿El plan de observabilidad se relaciona con escenarios concretos? | Sí: cada señal cita F-xx o T-xx |
| ¿El ADR 5 registra decisiones reales del equipo? | Sí: el equipo las tomó el 2026-11-06 sobre la propuesta de la IA, con condiciones propias |
| ¿La fitness function se puede ver ejecutándose en CI? | Sí: pestaña Actions, workflow `fitness-functions` |

## 3. Novedades e inconsistencias encontradas

| # | Severidad | Inconsistencia | Dónde | Qué se hizo | Quién decide |
|---|---|---|---|---|---|
| I-01 | **Alta** | La condición del ADR-04 (R-10) vencía al cierre de la Semana 13 y `main` sigue sin `restart:` | `dossier/evidencia-comite-adr04.md`, `docker-compose.yml` | Implementada y probada; cumplida el 2026-11-06 al fusionarse el PR #83. Seguimiento en ADR-04 | Equipo: fusionar y dar por cumplida la condición |
| I-02 | **Alta** | El plan M6-3 pone R-10 primero y R-11 cuarta, pero R-10 sola borra los datos en cada caída | `docs/registro-ia-modulo6.md`, exp. 16 HR2 | Decidido por el equipo el 2026-11-06: R-11 entra con R-10 | Equipo: cambiar el orden |
| I-03 | **Alta** | El escenario 2 y QA-01 son prioridad alta y nunca se implementaron | `dossier/04-escenarios-calidad.md`, `dossier/02` | Capa candidata en el PR | Equipo, en ADR-05 |
| I-04 | **Alta** | `dossier/02` pide la BD en red privada (R-05), y `docker-compose.yml` la publica con una contraseña versionada. ADR-04 afirma que D1 no abre canales nuevos | P07 | Corregido en el PR | Equipo |
| I-05 | Media | El C4 dice `JSON/HTTPS`, pero la API es HTTP en claro | `dossier/06-c4-contenedores.md`, P11 | Diagrama corregido: muestra el proxy TLS de producción y HTTP solo en la red interna (2026-11-06) | Equipo |
| I-06 | Media | ADR-01 habla de "un único punto de autenticación", que no existe | `adr/adr-01-decision-estilo.md` | Nota con fecha en ADR-01 | Equipo |
| I-07 | Media | `R-xx` significa cosas distintas: tácticas (`docs/resiliencia`), riesgos (`dossier/02` y `dossier/04-riesgos.md`, con listas diferentes), relaciones R1–R5 y reglas de FF-01 | Varios | Glosario de identificadores en el README | Equipo |
| I-08 | Media | R-06 figuraba como **Probada** ("nunca 500") y una entrada de 300 caracteres da 500 | `docs/resiliencia/matriz-resiliencia.md` | Pasada a **Parcial**; añadido F-14; corregida en el PR | Equipo: validar el cambio |
| I-09 | Media | ADR-04 y A4 miden el margen del escenario 1 (búsqueda) con el p95 de **escritura**, porque `/buscar` es simulado. No hay evidencia de una búsqueda real | `adr/adr-04-distribucion.md`, `docs/distribucion/` | Nota con fecha en ADR-04 y en A4; RO-12 | Equipo |
| I-10 | Media | El README decía que los datos se conservan en el volumen, pero `create-drop` los borra al reiniciar la API | `README.md`, F-13 | Corregido en el PR | Equipo |
| I-11 | Media | `QA-03` y `BIZ-01` significan cosas distintas en `dossier/02` y en `dossier/04`, y QA-02 sigue como "no medido" aunque hay evidencia | `dossier/02`, `dossier/04` | Nota con fecha en `dossier/02` y `dossier/04` | Equipo |
| I-12 | Media | El sílabo y el arco del proyecto no están en el repositorio, y la guía del tutor los cita | — | El tutor confirmó con el sílabo el cronograma de los comités (2026-11-06). Falta contrastar con la rúbrica | Equipo: contrastar con la rúbrica |
| I-13 | Media | CI no ejecuta las pruebas: el test de rollback (QA-02) solo corre a mano | `.github/workflows/` | Registrado como RO-11 | Equipo |
| I-14 | Baja | Calendario: la guía pone las semanas 13–14 en el Módulo 7, y el README titula "Módulo 6 (Semanas 11–14)" | `README.md` | Nota en el README | Equipo |
| I-15 | Baja | Del 2026-10-24 al 2026-10-31 no hay commits de la cuenta de Kevin en `main`, aunque esos documentos llevan los dos nombres | `git log` | Se anota; no es un error, pero el tutor pide contribuciones identificables | Equipo |
| I-16 | Baja | Las rutas sugeridas no coinciden con las del repositorio: `docs/ADR-05.md` frente a `adr/`, `experimentos/seguridad/` frente a la numeración. Tampoco existe `docs/11-*`, y `dossier/10`, `12` y `13` tratan otros temas | — | Se siguieron las convenciones del repositorio, como permite la guía | Equipo: confirmar con el tutor |
| I-17 | Media | En el computador del equipo, dos corridas de la defensa de S8 no sostuvieron 100 req/s: una se bloqueó a los 4 s y la otra dio un p95 de 2,98 s. En S11 se sostuvieron unas 196 req/s con un p95 de unos 51 ms. Cambian la máquina, el código y el modelo de carga | `experimentos/defensa-s8-historico/` (registro histórico, recuperado el 2026-11-06) | Se registró como RO-15 sin cambiar ADR-04 | Equipo: repetir la carga en su computador con el código actual |

## 4. Pendientes que dependen del equipo

Actualizado el 2026-11-06.

1. Confirmar con el profesor la categoría del catálogo y contrastar con la rúbrica (I-12, I-16). El tutor ya confirmó con el sílabo que ADR-05 no tiene mini-comité: se presenta en el comité técnico final, semanas 15–16.
2. Elegir proveedor y convertir el costo a COP (punto 7).
3. Antes de desplegar: las prioridades de `docs/13-riesgos-tradeoffs.md` §5.

Cerrados: fusión de todos los PR del módulo (§5); prueba en Windows (`docs/verificacion/windows-2026-11-06/`); revisión manual S6 (`docs/verificacion/revision-manual-s6-2026-11-06/`); rama temporal de verificación borrada.

Riesgo aceptado, no eliminado: la credencial histórica (RS-17). El tratamiento está decidido y documentado: según el equipo no se usó fuera de sus computadores, se da por comprometida, no se reutiliza y no se purga el historial (2026-11-06). La exposición en el historial de Git sigue existiendo como riesgo residual, aceptado en ADR-05.

## 5. Inventario de pull requests del módulo 7

Fusionados en `main`, uno por actividad, en este orden:

| PR | Qué entregó | Fusionó | Fecha |
|---|---|---|---|
| #82 | Experimentos 14, 15 y 16: fuga de datos, costo de seguridad y reinicio automático | Kevin Torres | 2026-11-06 |
| #83 | Capa JWT, R-10 + R-11, proxy TLS y FF-02 | Kevin Torres | 2026-11-06 |
| #84 | Documentación del módulo: seguridad, despliegue, riesgos, ADR-05 y EDAV 3 | Daniel Charry | 2026-11-06 |
| #85 | Verificación del README en Windows | Kevin Torres | 2026-11-06 |
| #86 | Registro histórico de las pruebas de carga de la defensa de S8 | Kevin Torres | 2026-11-06 |
| #87 | Revisión manual de riesgos y umbrales (S6) | Kevin Torres | 2026-11-06 |
| #88 | Estados tras las fusiones (preauditoría, primera pasada) | Kevin Torres | 2026-11-06 |
| #89 | C4, línea base y pendientes (preauditoría, segunda pasada) | Kevin Torres | 2026-11-06 |

Este inventario lo agregó el PR #90 (tercera pasada de la preauditoría), que por eso no aparece en la tabla: su fusión queda registrada en GitHub, igual que la de cualquier PR posterior.

Revisado por: Kevin Torres · Daniel Charry · Fecha: 2026-11-06
