# Reproducción de las mediciones del Spike 1 (Y1–Y5)

Fecha de ejecución: 2026-10-09 23:53 – 2026-10-10 00:01 UTC.
Objetivo: comprobar si las mediciones registradas en [`06-spike-resultado-s10.md`](../../06-spike-resultado-s10.md) se obtienen de nuevo desde el repositorio. La hipótesis, los criterios y el protocolo son los de [`04-spike-especificacion-s9.md`](../../04-spike-especificacion-s9.md) y no se modificaron. Este documento registra mediciones; **no emite veredicto**.

La evidencia original de `experimentos/spike-s10/` no se tocó.

## Commits medidos

| Estado | Commit | Cómo se obtuvo |
|---|---|---|
| Base | `887ccf1c634258f9a4a33d64e0a4de99d1c00f10` | `git worktree add ../PatitasUrbanas-base 887ccf1` |
| Reorganizado | `1e522df855f91c534be81d96b1e6fe7d11f09c68` | `git worktree add ../PatitasUrbanas-spike 1e522df` |
| Control Y2 | `4883f9cd8ac5de00debcfa812ffb9ba25ac56b2b` | `git worktree add ../PatitasUrbanas-control origin/spike/control-y2-descartable` |
| `main` actual | `3e567422e38e074357c48838ffe5caedb9215aa0` | clon principal |

Los scripts `revisar_modulos.py` y `medir_y3.sh` se ejecutaron desde `main`; `git diff af02cce origin/main` sobre ambos sale vacío (idénticos a los usados en la medición original). `git diff 1e522df origin/main -- app` también sale vacío.

## Entorno ([`entorno.txt`](./entorno.txt), [`postgres-version.txt`](./postgres-version.txt))

| Componente | Original (2026-10-02) | Esta reproducción |
|---|---|---|
| SO | Ubuntu 24.04.4 LTS (contenedor Linux) | Ubuntu 24.04.5 LTS (contenedor Linux en la nube, Claude Code) |
| Docker | 29.6.2 | 29.8.2 |
| Docker Compose | v5.3.1 | v5.6.0 |
| JDK | OpenJDK 21.0.11 | OpenJDK 21.0.12.1 |
| Maven | 3.9.11 | 3.9.11 |
| PostgreSQL (`postgres:16`) | 16.15 | 16.15 (Debian 16.15-1.pgdg13+2) |
| Python | no registrado | 3.13.16 |
| `maven:3.9.9-eclipse-temurin-21 mvn -v` | no ejecutado (D2) | Maven 3.9.9, Java 21.0.7 Temurin |

Las versiones son las mismas antes y después dentro de esta reproducción.

## Comandos

| Métrica | Comando | Repeticiones |
|---|---|---|
| Y1 | [`ejecutar_y1.sh`](./ejecutar_y1.sh): por corrida `docker compose down -v`, `docker compose up -d postgres_db`, espera a `healthy`, `mvn -B clean test` desde `app/` | 3 antes / 3 después |
| Y2, Y4, Y5 | `python3 experimentos/spike-s10/revisar_modulos.py <worktree>/app` | 1 antes / 1 después / 1 control / 1 `main` |
| Y3 | desde la raíz de cada worktree: `experimentos/spike-s10/medir_y3.sh <salida>` (script de `main`) | 3 por solicitud y estado |

Todas las corridas de Y1 e Y3 válidas se hicieron con `COMPOSE_PROJECT_NAME=patitasurbanas` (ver desviación R2).

## Resultados medidos

| Métrica | Base `887ccf1` | Reorganizado `1e522df` | Original registrado | ¿Coincide con el original? |
|---|---|---|---|---|
| Y1 | 2 tests, 0 fallos/errores/omitidos, en 3/3 corridas ([`antes/y1-corrida-*.log`](./antes/)) | 2 tests, 0 fallos/errores/omitidos, en 3/3 corridas ([`despues/`](./despues/)) | 2/2 en 3/3 antes y después | Sí |
| Y2 | 0 (8 imports evaluados) | 0 (5 imports evaluados) | 0 / 0 | Sí |
| Y3 | S1, S2: `201` `{estado, etapaInicial}` + `idSolicitud` numérico; S3: `200` `{status, mensaje}`; 9/9 repeticiones coinciden | idéntico; 9/9 coinciden; 0 diferencias antes vs después | 0 diferencias | Sí ([`y3-comparacion.txt`](./y3-comparacion.txt)) |
| Y4 | 0/7 (0%) | 7/7 (100%) | 0% → 100% | Sí |
| Y5 | 1 (`api.controller`) | 0 | 1 → 0 | Sí |

Tests ejecutados en cada corrida: `PatitasUrbanasApplicationTests` y `AdopcionControllerRollbackIntegrationTest`. No hubo resultados distintos entre corridas del mismo estado.

Comparación byte a byte con la evidencia original:

- `antes/y2-y4-y5.txt`, `despues/y2-y4-y5.txt` y `control-y2/salida.txt` son idénticos a los originales.
- Los 18 pares `status` + `norm.json` de Y3 son idénticos a los de `spike-s10/{antes,despues}/y3/`.
- Los listados de clases coinciden con los originales (salvo la línea de encabezado que tenía el original).

## Validación de instrumentos

| Instrumento | Resultado en esta reproducción |
|---|---|
| Control Y2 (rama `spike/control-y2-descartable`) | Y2 = 1, `MascotaController -> SolicitudAdopcionRepository` PROHIBIDO ([`control-y2/salida.txt`](./control-y2/salida.txt)) |
| Control Y4/Y5 | Las 7 clases del mapeo + `PatitasUrbanasApplication` aparecen tanto en la salida del script como en `find app/src/main/java -name '*.java'` ([`antes/listado-clases.txt`](./antes/listado-clases.txt), [`despues/listado-clases.txt`](./despues/listado-clases.txt)) |
| Y3 | 3/3 repeticiones coinciden en cada solicitud y estado |
| Y1 | Ningún test inestable |

## Estado de `main`

`revisar_modulos.py` sobre `app/` de `main` (`3e56742`) da Y2 = 0, Y4 = 100%, Y5 = 0, y su salida es idéntica a la del estado `1e522df` ([`main/y2-y4-y5.txt`](./main/y2-y4-y5.txt)). El import prohibido de la rama de control no está en `main`.

## Desviaciones de esta reproducción

| # | Desviación | Efecto |
|---|---|---|
| R1 | Docker Hub respondió `429 Too Many Requests` al descargar `postgres:16` y `maven:3.9.9-eclipse-temurin-21`. Se descargaron de `mirror.gcr.io/library/…` y se re-etiquetaron con el mismo nombre; `docker-compose.yml` no se modificó. | La versión de PostgreSQL resultante (16.15) es la misma que en la medición original. |
| R2 | Primer intento inválido: con dos worktrees de nombre distinto, Compose usó dos proyectos y el `container_name` fijo chocó; las corridas Y1 "después" no tuvieron BD limpia y `medir_y3.sh` abortó. Se repitió todo Y1 e Y3 con `COMPOSE_PROJECT_NAME=patitasurbanas`. | Los registros del intento fallido se conservan sin editar en [`invalidadas/`](./invalidadas/) y no se usan como resultado. |
| R3 | Versiones distintas de la medición original (Docker, Compose, JDK, SO de parche). | Antes y después usan el mismo entorno en esta reproducción. |
| R4 | Igual que D3 del original: `medir_y3.sh` hace una solicitud de arranque a `/api/mascotas/buscar?lat=0&lng=0&radio=1`. | No se cuenta en Y3. |
| R5 | La JVM del contenedor imprime `Picked up JAVA_TOOL_OPTIONS` con la configuración del proxy de red del entorno. | Solo aparece en los logs; no cambia la configuración de la aplicación. |

## No verificado en esta reproducción

- Ejecución en Windows/WSL2.
- Construcción de la imagen Docker de la API (`app/Dockerfile`, `docker compose up api_app`). Solo se comprobó `mvn -v` dentro de la imagen de compilación.
- Todo lo listado en la §6 de `06-spike-resultado-s10.md` sigue sin verificar.
