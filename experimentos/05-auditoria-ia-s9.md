# EDAV 2 — Evidencia de Delegación, Auditoría y Validación
## Ciclo: Spike de fronteras modulares — Semanas 9 (especificación) y 10 (ejecución)

> Semana 9: metadatos de la especificación, §1 y las dos primeras filas de §2.
> Semana 10: metadatos de la ejecución, §2 (resto), §3, §6 y §7 con hechos verificables. §4 contiene **hallazgos propuestos** que el equipo debe verificar y decidir; §5 y §8 (decisiones, resultado integrado y firma) son del equipo.

## 0. Metadatos del ciclo

| Campo | Valor |
|---|---|
| Fecha de especificación | 2026-10-01 (versión inicial, `8a2a001`); completada 2026-10-02 (`99269dd`, `c16cd03`) |
| Fecha de auditoría | 2026-10-02 |
| Integrante(s) que redactan y firman este EDAV | Charry Ríos Daniel Estiven y Kevin Steven Torres Caro |
| Herramienta/agente delegado | Claude Code (Anthropic) |
| Modelo/versión, si aplica | Claude Code (Anthropic); el identificador concreto del modelo no se registra en el repositorio |
| Rama de trabajo | `spike/fronteras-modulares-s10` (control de Y2: `spike/control-y2-descartable`, no se integra) |
| Commit base | `887ccf1` |
| Commit del resultado delegado | `1e522df` (código), `d97cbf3` (mediciones), `e9bcd93` (registro y veredicto) |
| Artefacto(s) producido(s) por el agente | Reorganización de paquetes en `app/`; `experimentos/spike-s10/revisar_modulos.py`; `experimentos/spike-s10/medir_y3.sh`; salidas en `experimentos/spike-s10/`; `experimentos/06-spike-resultado-s10.md`; rama de control `spike/control-y2-descartable` (`4883f9c`) |

## 1. Especificación entregada al agente

### 1.1 Objetivo y alcance

Reorganizar las clases existentes de `com.patitasurbanas.api` en paquetes por dominio (`adopciones/`, `mascotas/`, `shared/`, `config/`; `veterinarias/` declarada sin clases) sin cambiar lógica, para probar ADR-01 y las reglas de ADR-02. Detalle: [04-spike-especificacion-s9.md §2 y §4](./04-spike-especificacion-s9.md).

### 1.2 Criterios de aceptación comunicados antes del resultado

Y4 = 100% de las 7 clases de producción en su módulo objetivo; Y5 = 0 paquetes que mezclan dominios; Y1 = 100% de los tests que pasaban antes siguen pasando; Y2 = 0 imports prohibidos; Y3 = 0 diferencias en S1–S3. Basta con que falle una métrica para refutar. Detalle: [04-spike-especificacion-s9.md §3](./04-spike-especificacion-s9.md).

### 1.3 Prompt exacto entregado

El prompt de [04-spike-especificacion-s9.md §6](./04-spike-especificacion-s9.md), en la versión del commit `c16cd03`. Si se entrega con cualquier variación, se copia aquí literalmente y se registra como desviación.

### 1.4 Entradas proporcionadas

Especificación del spike, ADR-01, ADR-02, `dossier/15-diseno-modular-s7.md`, árbol de clases bajo `app/src/main/java/com/patitasurbanas/api/`, suite de tests y solicitudes S1–S3 de §5. Detalle: [04-spike-especificacion-s9.md §6](./04-spike-especificacion-s9.md).

### 1.5 Restricciones e instrucciones de no modificar

No cambiar lógica, endpoints, `pom.xml`, `application.properties`, persistencia, Docker Compose ni infraestructura; no agregar ArchUnit, Spring Security, JPMS, bibliotecas ni microservicios; no editar ADRs ni documentos de semanas anteriores; no inventar código, mediciones ni evidencia; no cambiar criterios después de ver resultados. Detalle: [04-spike-especificacion-s9.md §4 y §6](./04-spike-especificacion-s9.md).

## 2. Evidencia temporal: especificación → commit → resultado

| Evento | Commit / hash | Fecha y hora | Evidencia verificable |
|---|---|---|---|
| Estado del repositorio antes de la delegación | `887ccf1` | 2026-10-01 22:48:50 -0500 | Merge del PR #45; último cambio en `app/`: `0a243b0` (2026-09-12) |
| Especificación registrada antes del resultado | `8a2a001`, `99269dd`, `c16cd03` | 2026-10-01 22:47:18 -0500; 2026-10-02 16:07:49 +0000; 2026-10-02 16:10:04 +0000 | `git log -- experimentos/04-spike-especificacion-s9.md`; ningún commit de `app/` posterior a `0a243b0` |
| Inicio de la delegación (scripts + línea base) | `af02cce` | 2026-10-02 17:05:08 +0000 | Salidas en `experimentos/spike-s10/antes/` |
| Primer resultado del agente (reorganización) | `1e522df` (control de Y2: `4883f9c`, 17:05:16) | 2026-10-02 17:05:49 +0000 | `experimentos/spike-s10/alcance-diff.txt` |
| Commit del resultado integrado en la rama de trabajo | `d97cbf3` (mediciones), `e9bcd93` (registro) | 2026-10-02 17:07:22 / 17:08:31 +0000 | `experimentos/spike-s10/despues/`, `experimentos/06-spike-resultado-s10.md` |
| Auditoría humana | (commit de esta auditoría) | 2026-10-02 | Decisiones de §4–§5 y firma de §8 |
| Correcciones posteriores, si las hubo | Eliminación del import de control fusionado por error (PR #50) — ver D5 / S5 | 2026-10-02 | `git diff 1e522df -- app` vacío |

### 2.1 Declaración de trazabilidad temporal

La especificación (`8a2a001`, `99269dd`, `c16cd03`) y ADR-03 (`403d7b5`) se registraron antes del primer commit de la ejecución (`af02cce`). La rama de ejecución parte de `887ccf1` y la línea base se midió antes de mover ninguna clase. Hipótesis y criterios no se modificaron después de conocer el resultado: el único cambio posterior a la especificación es el enlace a `06-spike-resultado-s10.md` en sus secciones "Resultado" y "Veredicto" (`e9bcd93`).

## 3. Resultado entregado por el agente antes de auditoría

Detalle completo en [06-spike-resultado-s10.md](./06-spike-resultado-s10.md).

| Métrica | Base | Después | Umbral | Cumple |
|---|---|---|---|---|
| Y1 | 2/2 tests en 3/3 corridas | 2/2 en 3/3 | 100% | Sí |
| Y2 | 0 | 0 | 0 | Sí |
| Y3 | — | 0 diferencias (9/9 respuestas iguales) | 0 | Sí |
| Y4 | 0/7 (0%) | 7/7 (100%) | 100% | Sí |
| Y5 | 1 | 0 | 0 | Sí |

Veredicto propuesto por el agente: hipótesis soportada en las condiciones registradas. Desviaciones declaradas: D1–D4 (entorno Linux, Maven local, solicitud de arranque en Y3, Y2 no ve referencias del mismo paquete).

## 4. Auditoría humana: hallazgos clasificados

> Hallazgos propuestos por el agente y revisados por el equipo. La columna "Decisión" registra la decisión del equipo (2026-10-02).

### 4.1 Hallazgos sustantivos

| # | Hallazgo | Evidencia | Clasificación | Decisión (aceptado / rechazado / corregido) | Commit de corrección, si aplica |
|---|---|---|---|---|---|
| S1 | El test `AdopcionControllerRollbackIntegrationTest` queda en el paquete de test `com.patitasurbanas.api.controller`, que ya no existe en producción. Moverlo no estaba en el alcance (solo se actualizan imports). | `git diff 887ccf1 1e522df -- app/src/test` | Sustantivo (coherencia estructural) | Aceptado. Seguimiento: mover el test al paquete de test `api.adopciones` en un cambio posterior al spike | |
| S2 | El medidor Y2 solo analiza `import`; las referencias entre clases del mismo paquete no se cuentan (los imports evaluados bajan de 8 a 5). | `spike-s10/antes/y2-y4-y5.txt` vs `spike-s10/despues/y2-y4-y5.txt`; desviación D4 | Sustantivo (limitación del instrumento) | Aceptado como limitación del medidor: las referencias no contadas están dentro de `adopciones/` | |
| S3 | La ejecución se hizo en Linux con Maven local; no se verificó Windows/WSL2 ni la construcción de la imagen Docker de la API. | `spike-s10/entorno.txt`; desviaciones D1–D2 | Sustantivo (validez externa) | Aceptado como no verificado: queda pendiente probar `docker compose up --build` en Windows/WSL2 | |
| S4 | No se crearon `shared/`, `config/` ni `veterinarias/`: ninguna clase existente pertenece a ellos. | `spike-s10/despues/listado-clases.txt` | Sustantivo (alcance) | Aceptado: ninguna clase existente pertenece a esos módulos | |
| S5 | La rama de control de Y2 se fusionó en `main` por error (PR #50, `af92e3f`) e introdujo el import prohibido. Se eliminó en la rama del spike; tras fusionar el PR del spike, `main` queda sin el import. | `git show af92e3f`; desviación D5 en `06-spike-resultado-s10.md` | Sustantivo (integridad del procedimiento) | Corregido | `36e2e97` |

### 4.2 Hallazgos cosméticos

| # | Hallazgo | Evidencia | Clasificación | Decisión (aceptado / rechazado / corregido) | Commit de corrección, si aplica |
|---|---|---|---|---|---|
| C1 | En `adopciones/` conviven controlador, servicio y repositorios en el mismo paquete; solo los modelos tienen subpaquete (`model/`), tal como indica `dossier/15`. | `spike-s10/despues/listado-clases.txt` | Cosmético | Aceptado: coincide con `dossier/15-diseno-modular-s7.md` | |
| C2 | `medir_y3.sh` hace una solicitud de arranque a `/api/mascotas/buscar` que no forma parte de S1–S3. | `spike-s10/medir_y3.sh`; desviación D3 | Cosmético | Aceptado: no afecta a S1–S3 | |

## 5. Decisiones sobre las sugerencias

### 5.1 Aceptado tal cual

- Reorganización de paquetes (`1e522df`): solo cambian declaraciones `package`/`import`.
- Scripts de medición `revisar_modulos.py` y `medir_y3.sh`, y sus salidas originales en `experimentos/spike-s10/`.
- Resultados Y1–Y5 y veredicto "hipótesis soportada" (`06-spike-resultado-s10.md`).
- Hallazgos S1, S2, S3, S4, C1 y C2 aceptados con las observaciones de §4.

### 5.2 Rechazado

- Ninguno.

### 5.3 Corregido o modificado

- S5: el import de control fusionado por error en `main` (PR #50) se eliminó en `36e2e97`; `app/` queda idéntico al estado medido.

## 6. Verificación del cambio

| Verificación | Comando o procedimiento | Evidencia/salida | Estado |
|---|---|---|---|
| Conteo antes de dependencias prohibidas | `python3 experimentos/spike-s10/revisar_modulos.py app` en `887ccf1` | `spike-s10/antes/y2-y4-y5.txt`: Y2 = 0 | Hecho |
| Validez del medidor Y2 | Import prohibido inyectado en `spike/control-y2-descartable` | `spike-s10/control-y2/salida.txt`: Y2 = 1 | Hecho (medidor válido) |
| Conteo después de dependencias prohibidas | Mismo script en `1e522df` | `spike-s10/despues/y2-y4-y5.txt`: Y2 = 0 | Hecho |
| Cálculo de la métrica frente al umbral predefinido | Y4 y Y5 con el mismo script | Y4 0% → 100%; Y5 1 → 0 | Hecho |
| Suite de pruebas existente | `mvn -B clean test` ×3 antes y ×3 después, BD limpia | `spike-s10/antes/y1-corrida-*.log`, `spike-s10/despues/y1-corrida-*.log`: 2/2 en todas | Hecho |
| Comportamiento observable de endpoints | `experimentos/spike-s10/medir_y3.sh` (S1–S3 ×3) | `spike-s10/y3-comparacion.txt`: 9/9 iguales | Hecho |
| Revisión humana del diff | `git diff -M -U0 887ccf1 1e522df -- app` filtrado a líneas que no son `package`/`import` | `spike-s10/alcance-diff.txt`: 8 archivos, ninguna línea fuera de `package`/`import`; aceptado por Charry Ríos Daniel Estiven y Kevin Steven Torres Caro sobre esta evidencia | Hecho |

## 7. Qué no se alcanzó a verificar

- Ejecución en Windows/WSL2 y construcción de la imagen Docker de la API (`docker compose up --build api_app`).
- `POST /api/adopciones/test-fallo` fuera del test de rollback.
- Entradas no válidas o casos límite de los endpoints (Y3 cubre solo S1–S3).
- Cumplimiento futuro de las fronteras (siguen siendo convención, ADR-02).
- Seguimiento de S1 (ubicación del test) queda fuera de este spike.

## 8. Resultado integrado y responsabilidad de auditoría

Se integra a `main` mediante el PR #49 todo el contenido de la rama `spike/fronteras-modulares-s10`: la reorganización de paquetes, los scripts y las evidencias de `experimentos/spike-s10/`, el registro `06-spike-resultado-s10.md`, ADR-03 actualizado y `dossier/17-cqrs-consistencia-eventual-s10.md`. No se integra la rama `spike/control-y2-descartable`; su import ya integrado por error se elimina (S5).

Declaro que revisé el resultado entregado por el agente y las decisiones de esta auditoría, y que estoy dispuesto a defender el resultado integrado.

Nombre(s): Charry Ríos Daniel Estiven y Kevin Steven Torres Caro

Fecha: 2026-10-02
