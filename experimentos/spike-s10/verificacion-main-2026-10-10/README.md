# Verificación sobre el `main` actual (2026-10-10)

Ejecución: 2026-10-10 01:04 – 01:07 UTC, en un contenedor Linux (Claude Code en la nube).
Objetivo: comprobar que el estado actual de `main` reproduce las mediciones del Spike 1 que respaldan el veredicto. Hipótesis, criterios y scripts sin cambios. Este documento registra mediciones; **no emite veredicto**.

## Commit medido

- `main` = `6465b1ae85189fd8a0e0790c6a40ea383a330386` (merge del PR #64).
- Árbol de `app/`: `cef127273b526a70c3a0e65410127de132f2e81e`, el mismo objeto que en `1e522df` (nuevo hash `44ede36`, ver Anexo A de [09-cierre-spike-s10.md](../../09-cierre-spike-s10.md)).
- Scripts: `experimentos/spike-s10/revisar_modulos.py` y `medir_y3.sh` tal como están en `main`.

Entorno en [`entorno.txt`](./entorno.txt) y [`postgres-version.txt`](./postgres-version.txt): Ubuntu 24.04.5, OpenJDK 21.0.12.1, Maven 3.9.11, Docker 29.8.2, Compose v5.6.0, PostgreSQL 16.15. Es el mismo entorno que la reproducción del 2026-10-09, no el de la medición original.

## Comandos

| Métrica | Comando | Repeticiones |
|---|---|---|
| Y2, Y4, Y5 | `python3 experimentos/spike-s10/revisar_modulos.py app` | 1 |
| Y1 | [`ejecutar.sh`](./ejecutar.sh): por corrida `docker compose down -v`, `docker compose up -d postgres_db`, espera a `healthy`, `mvn -B clean test` desde `app/` | 3 |
| Y3 | `experimentos/spike-s10/medir_y3.sh experimentos/spike-s10/verificacion-main-2026-10-10/y3` (dentro de `ejecutar.sh`) | 3 por solicitud |

Con `COMPOSE_PROJECT_NAME=patitasurbanas` en todas las corridas.

## Resultados

| Métrica | `main` (`6465b1a`) | Registrado para `1e522df` | Evidencia |
|---|---|---|---|
| Y1 | 2 tests, 0 fallos/errores/omitidos, `BUILD SUCCESS` en 3/3 corridas | 2/2 en 3/3 | [`y1-corrida-*.log`](./) |
| Y2 | 0 | 0 | [`y2-y4-y5.txt`](./y2-y4-y5.txt) |
| Y3 | S1, S2: 201; S3: 200; 3/3 repeticiones coinciden; 0 diferencias frente a `spike-s10/despues/y3` | 0 diferencias | [`y3-comparacion.txt`](./y3-comparacion.txt), [`y3/`](./y3/) |
| Y4 | 7/7 (100%) | 7/7 | [`y2-y4-y5.txt`](./y2-y4-y5.txt) |
| Y5 | 0 | 0 | [`y2-y4-y5.txt`](./y2-y4-y5.txt) |

`y2-y4-y5.txt` es idéntico byte a byte a `spike-s10/despues/y2-y4-y5.txt`.

## Hallazgo S1 de la EDAV 2

**Sigue abierto.** `AdopcionControllerRollbackIntegrationTest` está en `app/src/test/java/com/patitasurbanas/api/controller/` con `package com.patitasurbanas.api.controller;` ([`listado-tests.txt`](./listado-tests.txt)), y los logs de Y1 lo ejecutan como `com.patitasurbanas.api.controller.AdopcionControllerRollbackIntegrationTest`. Ningún commit ha tocado `app/src/test` desde `1e522df`/`44ede36`. No se movió en esta verificación.

## No verificado aquí

- Windows/WSL2, el `app/Dockerfile` original y `docker compose up --build`.
- Casos fuera de S1–S3 y de los 2 tests existentes.
