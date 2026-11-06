# EDAV 3 — Evidencia de Delegación, Auditoría y Validación
## Ciclo: Seguridad, despliegue y operación — Semanas 13 y 14

> **Estado: auditado y firmado por el equipo el 2026-11-06.** La IA redactó §0–§3, §6 y §7. Las decisiones de §4 y §5 y el texto de §8 son del equipo: los envió por chat el 2026-11-06 y la IA los transcribió. Este ciclo es formativo según la indicación del tutor.

## 0. Metadatos del ciclo

| Campo | Valor |
|---|---|
| Fecha de especificación | 2026-11-05 |
| Fecha de auditoría | 2026-11-06 |
| Integrante(s) que redactan y firman este EDAV | Kevin Torres · Daniel Charry |
| Herramienta/agente delegado | Claude (Anthropic) |
| Modelo/versión, si aplica | `claude-opus-5-5` configurado en la sesión; el modelo que atendió cada turno puede diferir |
| Rama de trabajo | `experimento/s13-s14-seguridad-operacion`, `feat/s13-capa-seguridad`, `modulo7/documentacion-s13-s14` |
| Commit base | `3f4b124` |
| Commit del resultado delegado | Ver §2 |
| Artefacto(s) producido(s) por el agente | Experimentos 14, 15 y 16; capa de seguridad, Compose de producción y FF-02; `docs/10`, `docs/12`, `docs/13`; ADR-05; matrices actualizadas; este borrador |

## 1. Especificación entregada al agente

### 1.1 Objetivo y alcance

Texto exacto del pedido del 2026-11-05:

> "Bueno chat vamos a realizar lo que nos dijo el tutor sobre las siguientes semanas, hagamos todo y validemos que se encuentre en el repositorio https://github.com/Charry21/PatitasUrbanas.git Cualquier novedad o inconsistencia a resaltar me avisas"

Junto con el pedido se entregó la guía del tutor con los entregables de las semanas 13 y 14.

Pedido posterior, del 2026-11-06, sobre la verificación local:

> "Queremos omitir lo del paso 2, lo puedes hacer tu, para el paso 3 cuales son las decisiones que tenemos que revisar, nos la das por aca para validarlas y asi ya poder firmar ese documento y lo que haga falta"

### 1.2 Criterios de aceptación comunicados antes del resultado

Los de la lista de verificación del tutor (17 puntos), revisados uno por uno en [`auditoria-modulo7.md`](./auditoria-modulo7.md).

### 1.3 Prompt exacto entregado

El de §1.1, más la guía del tutor. No se versionó antes de ejecutar; este documento lo registra después. Esa es una limitación de la trazabilidad temporal del prompt.

### 1.4 Entradas proporcionadas

Guía del tutor y acceso de escritura al repositorio con el usuario `kevinsteven1007-glitch`. El agente **no recibió** `SILABO_v1.1.1_Arquitectura_de_Software.md` ni `01-arco-del-proyecto.md`, que la guía cita.

### 1.5 Restricciones e instrucciones de no modificar

El pedido no fijó restricciones explícitas. La guía del tutor exige no presentar como concluyente lo que no lo es, usar commits y pull requests, y registrar decisiones reales del equipo. El agente aplicó además las normas del dossier: preregistrar antes de medir, no inventar evidencia y no firmar por el equipo.

## 2. Evidencia temporal: especificación → commit → resultado

Horas en UTC. Los hashes se pueden comprobar con `git log` en cada rama.

| Evento | Commit / hash | Fecha y hora | Evidencia verificable |
|---|---|---|---|
| Estado del repositorio antes de la delegación | `3f4b124` | 2026-10-30 | Merge del PR #81 |
| Preregistro de los experimentos 14, 15 y 16 | `3c2b010`, `0e9c109`, `c00438b` | 2026-11-06 01:52:50 | PR #82 abierto a las 01:52:53, antes de medir |
| Corrección de 2 errores de Bash del script de fuga | `03e4c74` | 2026-11-06 | Desviación D1 de `experimentos/14-fuga-datos-s13/RESULTADOS.md` |
| Primer resultado: fuga sobre `main` | `c99a20c` | 2026-11-06 | `experimentos/14-fuga-datos-s13/resultados/antes/` |
| Resultado del reinicio | `15b6708` | 2026-11-06 | `experimentos/16-reinicio-automatico-s14/` |
| Capa de seguridad medida | `07c8cac` | 2026-11-06 | Rama `feat/s13-capa-seguridad` |
| Medición del p95 | `b9f135f` (datos), `54bc0ab` (informe) | 2026-11-06 | `experimentos/15-costo-seguridad-s13/` |
| Auditoría humana | Conversación del 2026-11-06 | 2026-11-06 | Decisiones de §4 y §5, texto de §8 |

### 2.1 Declaración de trazabilidad temporal

Las hipótesis y los criterios se versionaron antes de cualquier ejecución. Dos matices:

- **El preregistro no estaba fusionado en `main` al ejecutar**, a diferencia de los PR #76 y #79: quedó en un PR abierto, porque la fusión es del equipo. El orden se comprueba con las fechas de los commits y del PR.
- **El autor del preregistro ya había leído la configuración**, así que varias predicciones eran previsibles. Sirven para fijar los criterios, no como prueba de capacidad de predicción.

## 3. Resultado entregado por el agente antes de auditoría

| Entregable | Resultado |
|---|---|
| Modelado de amenazas | 18 amenazas STRIDE en `docs/10-seguridad.md` |
| Matriz de riesgos y controles | 17 riesgos con propuesta de mitigar o aceptar |
| Fuga de datos | `main`: 7 sondas con fuga y 1 hallazgo. Con los controles: 1 fuga parcial (P08). 0 de 26 predicciones refutadas |
| Costo sobre el p95 | Δ(C − S) de +5,23 y +9,72 ms, con evidencia débil; TLS no concluyente; HC1–HC5 no refutadas |
| R-10 y R-11 | R-10 recupera en < 10 s; con `create-drop` se pierden los datos; con `update` se conservan |
| Despliegue y observabilidad | `docs/12-despliegue-observabilidad.md` |
| Riesgos y compromisos | 14 riesgos operativos y 10 compromisos en `docs/13-riesgos-tradeoffs.md` |
| ADR-05 | Estado **Propuesta** |
| FF-02 | En CI en el PR #83, con prueba negativa de 10 casos |

## 4. Auditoría humana: hallazgos clasificados

> Hallazgos propuestos por el agente. La columna "Decisión" la definió el equipo el 2026-11-06.

### 4.1 Hallazgos sustantivos

| # | Hallazgo | Evidencia | Clasificación sugerida | Decisión (aceptado / rechazado / corregido) | Commit de corrección, si aplica |
|---|---|---|---|---|---|
| S1 | La capa de seguridad es una candidata construida por la IA. El pedido no la mencionaba: hizo falta para poder medir | `experimentos/15-costo-seguridad-s13/README.md` §1 | Sustantivo (alcance) | Aceptado | |
| S2 | El agente cambió configuración y código más allá de los documentos: Compose, Dockerfile, contrato y README | `git diff main...feat/s13-capa-seguridad` | Sustantivo (alcance) | Aceptado | |
| S3 | Se propone cambiar el orden aceptado en M6-3: R-11 con R-10 | HR2 del experimento 16 | Sustantivo (decisión previa) | Aceptado: R-11 entra con R-10 (ADR-05, decisión D) | |
| S4 | Las mediciones de p95 usaron `Dockerfile.runtime`, no `app/Dockerfile`. La construcción real se verificó aparte, sin medir | `experimentos/10-crecimiento-s11/entorno/Dockerfile.runtime` | Sustantivo (validez externa) | Aceptado como limitación: métricas de un entorno aislado | |
| S5 | `despues` usa certificado local; no hay prueba con un dominio real | `experimentos/14-fuga-datos-s13/RESULTADOS.md` | Sustantivo (validez externa) | Aceptado como limitación | |
| S6 | Probabilidades, impactos y umbrales de alerta son juicio de la IA | `docs/10-seguridad.md` §4 | Sustantivo (criterio) | **Pendiente de corregir:** el equipo lo considera crítico y exige revisar a mano probabilidades, impactos y umbrales antes de desplegar. Hasta entonces siguen siendo juicio de la IA | |
| S7 | Los tokens los generó el mismo experimento: no se probó un emisor real | `generar_tokens.py` | Sustantivo (validez externa) | Aceptado como limitación; emisor aplazado (solución de terceros) | |
| S8 | La primera versión de la capa rompía los errores 400 y las pruebas con MockMvc no lo vieron. Lo destapó la lectura de los códigos de P04 | `experimentos/14-fuga-datos-s13/RESULTADOS.md` §4, H2 | Sustantivo (calidad de las pruebas) | Corregido. El equipo pide además reforzar las pruebas de integración | `94f2acf` |
| S9 | FF-02 tenía un falso positivo, y su prueba negativa daba verde igual porque la base ya fallaba | Commit `68f01c1` | Sustantivo (instrumento) | Corregido | `68f01c1` |
| S10 | El agente commiteó durante una corrida válida del experimento 15 | `experimentos/15-costo-seguridad-s13/RESULTADOS.md` §6, D1 | Sustantivo (procedimiento) | Aceptado como desviación | |

### 4.2 Hallazgos cosméticos

| # | Hallazgo | Evidencia | Clasificación sugerida | Decisión (aceptado / rechazado / corregido) | Commit de corrección, si aplica |
|---|---|---|---|---|---|
| C1 | Los experimentos no usan las rutas sugeridas por el tutor, sino la numeración del repositorio | `experimentos/14-…`, `15-…`, `16-…` | Cosmético | Aceptado | |
| C2 | ADR-05 está en `adr/`, no en `docs/ADR-05.md` | `adr/adr-05-seguridad-y-operacion.md` | Cosmético | Aceptado | |

## 5. Decisiones sobre las sugerencias

### 5.1 Aceptado tal cual

- S1, S2 y S3 (cambio de orden de M6-3), S10, C1 y C2.
- Aceptados como limitación: S4, S5 y S7.
- Las decisiones de ADR-05: aceptadas, con el emisor de tokens aplazado (`adr/adr-05-seguridad-y-operacion.md`).

### 5.2 Rechazado

Ninguno.

### 5.3 Corregido o modificado

- S8: corregido en `94f2acf`. El equipo pide reforzar las pruebas de integración con servidor real y en CI.
- S9: corregido en `68f01c1`.
- S6: **corrección pendiente**. Antes de desplegar, el equipo revisará a mano las probabilidades, los impactos y los umbrales.

## 6. Verificación del cambio

| Verificación | Comando o procedimiento | Evidencia/salida | Estado |
|---|---|---|---|
| Suite de pruebas | `mvn -B clean package` con PostgreSQL local | 11/11 en `94f2acf` | Hecho |
| Fronteras modulares | `python3 -I tools/fitness/fronteras_modulares.py app` | 8 clases, 0 violaciones | Hecho |
| Fuga de datos, antes y después | `experimentos/14-fuga-datos-s13/ejecutar.sh` | `comparacion.tsv` de cada etiqueta | Hecho |
| Costo sobre el p95 | `experimentos/15-costo-seguridad-s13/ejecutar.sh` y `analizar.py` | `resultados/analisis.txt` | Hecho |
| Reinicio | `experimentos/16-reinicio-automatico-s14/ejecutar.sh` | `resultados/bitacora.txt` | Hecho |
| FF-02 y su prueba negativa | Workflow `fitness-functions` | Ejecución `42153384163` (PR #83, `94f2acf`), *success*; pasos en `docs/fitness/evidencias/ejecuciones-ci-2026-11-05.txt` | Hecho |
| Construcción con `app/Dockerfile` y arranque limpio | `verificar.sh` en GitHub Actions, ejecución `42232989485` | 0 comprobaciones fallidas; `docs/verificacion/arranque-limpio-2026-11-06/` | Hecho por la IA a pedido del equipo, en Linux |
| Lo mismo en un computador del equipo con Windows | README | — | **Pendiente del equipo** |
| Revisión humana | Decisiones de §4 y §5 | Hecha por el equipo el 2026-11-06 | Hecho. Falta la aprobación del PR por Daniel Charry en GitHub |

## 7. Qué no se alcanzó a verificar

- Un emisor real de tokens.
- Un despliegue en un servidor y dominio reales.
- La restauración de una copia de la BD: no hay copias.
- La recuperación con tráfico concurrente.
- Las alertas de `docs/12-despliegue-observabilidad.md` §3.4: no están implementadas.
- El sílabo y el arco del proyecto: no se tuvo acceso a esos archivos.

## 8. Resultado integrado y responsabilidad de auditoría

Conclusión del equipo, transcrita sin cambios:

> Las decisiones estructuradas en el ADR-05 y el listado secundario construyen un entorno de desarrollo viable para la iteración actual, pero los hallazgos de la EDAV 3 demuestran que el proyecto opera bajo métricas y configuraciones simuladas. La dependencia de un emisor de tokens experimental, certificados locales y mediciones de rendimiento sin latencia de red documentan una alta acumulación de deuda técnica.
> 
> Para evitar conflictos en la estabilización de la arquitectura, la prioridad técnica debe centrarse en mitigar los hallazgos de la EDAV 3. Es imperativo ejecutar la revisión manual de los umbrales de impacto, sustituir los artefactos experimentales (como el emisor de tokens) por implementaciones definitivas, y robustecer las pruebas de integración para cubrir los puntos ciegos demostrados por `MockMvc` antes de proceder con el despliegue en un servidor proveedor.

Nombre(s): Kevin Torres · Daniel Charry

Fecha: 2026-11-06

Registro de la firma: Kevin Torres confirmó los nombres y la fecha en el chat con la IA el 2026-11-06. La aprobación del PR #84 por Daniel Charry deja constancia de su revisión.

---

## Anexo A. Análisis del equipo (texto recibido el 2026-11-06, sin cambios)

Análisis de decisiones y posibles conflictos (ADR-05 y Otras Decisiones)

* Identidad y Autenticación: Se aprueba la validación de JWT RS256 en la API con denegación por defecto, pero se aplaza la implementación del emisor de tokens hasta integrar una solución de identidad de terceros. Esto es funcional para el estado actual de Patitas Urbanas, pero genera un bloqueo arquitectónico; el sistema no podrá operar en un entorno real hasta que se defina e integre dicho proveedor.
* Exposición de Datos: Mantener el endpoint `/api/mascotas/buscar` público y sin token es aceptado condicionalmente mientras los datos sean simulados. Esto representa un riesgo si el paso a producción con datos reales se ejecuta sin antes implementar controles de acceso, comprometiendo la privacidad.
* Gestión de Riesgos Posteriores: Aceptar los riesgos de seguridad (RS-08 al RS-17) bajo la condición de revisarlos antes de un despliegue público o almacenamiento de datos personales es una práctica de postergación. Acumular la mitigación de vulnerabilidades y la definición de tiempos de retención de IP en los logs para las fases finales incrementa la deuda técnica del ciclo de vida del software.

Análisis de hallazgos (EDAV 3)

* Brechas en Pruebas de Integración: La corrección donde `MockMvc` no detectó que la primera capa rompía los errores 400 evidencia que el entorno de pruebas unitarias/integración no es completamente fiable para el enrutamiento y manejo de excepciones web.
* Sesgo en la Evaluación de Riesgos: El hallazgo que indica que las probabilidades, impactos y umbrales son juicio de la inteligencia artificial y requieren revisión manual es crítico. En el marco de la ingeniería de sistemas, delegar matrices de riesgo a estimaciones algorítmicas sin validación humana invalida la objetividad de la planeación de contingencias.
* Limitaciones de Entorno: La medición del percentil 95 (p95) usando `Dockerfile.runtime` y las pruebas TLS con un certificado local sin dominio real indican que las métricas de rendimiento y seguridad actuales son exclusivas de un entorno aislado (sandbox).

### Precisiones de la IA sobre el texto

El texto del equipo no se modifica. Para que no se lea mal, dos datos:

1. Los riesgos aceptados son RS-08, RS-09, RS-12, RS-13, RS-15 y RS-17. RS-10 y RS-11 se mitigan en el PR #83; RS-14 y RS-16 quedaron aplazados.
2. El sistema no tiene un emisor de tokens experimental: los tokens de las pruebas los genera `experimentos/14-fuga-datos-s13/generar_tokens.py`.
