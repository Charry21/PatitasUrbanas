# Hipótesis de Localización - Semana 6

## Hipótesis

Para la operación `POST /api/adopciones`, bajo una petición única y controlada, **más del 50% del tiempo total de respuesta HTTP corresponde al tiempo de ejecución de las consultas SQL** (suma de `total_exec_time` de las sentencias observadas en `pg_stat_statements` asociadas a la petición), y no a la lógica de aplicación en `AdopcionController` / `AdopcionService`.

## Operación asociada

POST /api/adopciones?estado=PENDIENTE&nombreEtapa=SOLICITUD_RECIBIDA (misma operación localizada en dossier/08-localizacion-s6.md)

## Métrica y fórmula de contraste

```
proporcion_bd = (suma de total_exec_time de las consultas de la peticion en pg_stat_statements) / (tiempo total de la peticion HTTP) * 100
```

- Tiempo total de la petición HTTP: medido con una sola ejecución vía Invoke-RestMethod cronometrada (Measure-Command) o con k6 apuntando una sola iteración a este endpoint.
- Tiempo de consultas SQL: suma de `total_exec_time` (en ms) de las 5 sentencias asociadas (BEGIN, INSERT solicitud_adopcion, SELECT FOR KEY SHARE, INSERT etapa_adopcion, COMMIT), obtenidas inmediatamente después de resetear `pg_stat_statements` y ejecutar una sola petición.

## Criterio de refutación

Si `proporcion_bd` resulta ≤ 50%, la hipótesis se considera **refutada**: la mayor parte del tiempo estaría en la aplicación (serialización, framework, red), no en la base de datos.

Si `proporcion_bd` resulta > 50%, la hipótesis se considera **soportada** (no "confirmada" de forma absoluta, solo bajo estas condiciones específicas).

## Condiciones de medición

Misma línea base congelada en experimentos/03-linea-base-semana6.md (commit fde35cfee5522303746db8a1f57e7df20ee00d45 o posterior, indicando el commit exacto usado en el momento de medir). Contenedor de base de datos ya estabilizado (sin reinicio reciente), siguiendo la lección aprendida en experimentos/01-metodologia-medicion.md sección 6 sobre warm-up extendido.

## Limitación reconocida de antemano

Esta medición compara un tiempo de aplicación medido en Windows/PowerShell (reloj de pared, incluye red y overhead del proceso k6/PowerShell) contra un tiempo de base de datos medido dentro del contenedor Postgres (pg_stat_statements). Ambos tiempos no son perfectamente comparables en la misma unidad de observación; el resultado debe interpretarse como una aproximación razonable, no como una descomposición exacta y aislada del tiempo total.

## Estado

Especificación registrada antes de ejecutar la medición que la contrasta. Fecha de especificación: 12 de septiembre de 2026. El resultado de la medición se documentará en un archivo separado (dossier/10-resultado-hipotesis-s6.md) una vez ejecutada, para preservar la trazabilidad temporal correcta.
