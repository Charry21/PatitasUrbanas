# Resultado de la Hipótesis de Localización - Semana 6

Contrasta la hipótesis registrada en dossier/09-hipotesis-localizacion-s6.md (commit 9af4a8dca64ce065137f3b7afd145efd780b093f, previo a esta medición).

## Procedimiento ejecutado

Se ejecutaron 4 repeticiones de POST /api/adopciones?estado=PENDIENTE&nombreEtapa=SOLICITUD_RECIBIDA, reseteando pg_stat_statements antes de cada una. La repetición 1 se descartó por mostrar un tiempo total anómalo (1290 ms, compatible con arranque en frío de esta ruta específica tras estar el contenedor inactivo). Las repeticiones 2, 3 y 4 se consideran válidas (número impar, mínimo 3, siguiendo el mismo criterio ya usado en experimentos/01-metodologia-medicion.md).

## Datos observados

| Corrida | Tiempo total HTTP (ms) | Tiempo SQL total (ms) | Proporción BD |
|---|---:|---:|---:|
| 1 (descartada) | 1290.07 | 9.60 | 0.74% |
| 2 (válida) | 41.17 | 3.80 | 9.23% |
| 3 (válida) | 58.19 | 1.86 | 3.19% |
| 4 (válida) | 28.82 | 0.57 | 1.96% |

Mediana de la proporción BD (corridas válidas 2, 3, 4): 3.19%

## Contraste contra el criterio de refutación

El criterio pre-registrado establecía: si `proporcion_bd` ≤ 50%, la hipótesis se considera refutada.

La mediana observada (3.19%) está muy por debajo del 50%.

## Veredicto

**Hipótesis REFUTADA.** Bajo las condiciones registradas, el tiempo de ejecución de las consultas SQL representa una fracción muy pequeña (entre 2% y 9%) del tiempo total de la petición HTTP. La mayor parte del tiempo de respuesta no corresponde a la base de datos, sino a otras capas (aplicación Spring/Tomcat, serialización, pool de conexiones, red entre el cliente PowerShell y el contenedor).

## Observación adicional (no diagnóstico)

Este resultado es una observación localizada bajo las condiciones específicas de esta medición (petición única, sin concurrencia). No identifica una causa específica dentro de la capa de aplicación, ni concluye que exista un problema de rendimiento. Determinar qué parte específica de la capa de aplicación consume el tiempo restante corresponde a un análisis posterior.

## Limitación reconocida

Como se anticipó en la especificación de la hipótesis, el tiempo total HTTP y el tiempo SQL se miden en relojes distintos (PowerShell/.NET vs. Postgres), por lo que la comparación es aproximada, no una descomposición exacta y aislada.
