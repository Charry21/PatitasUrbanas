# Semilla de datos y memoria de la API — Semana 12

> **Estado: preregistro.** Fija la pregunta, la semilla, la hipótesis, el procedimiento y el tratamiento de los datos **antes** de medir. Los resultados van en `RESULTADOS.md` en un commit posterior; las secciones 1–6 no se modifican después de ver los datos.

- Fecha del preregistro: 2026-10-24
- Código bajo prueba: `app/` de `main` al ejecutar (se registra el hash). El experimento **no modifica** `app/`.

## 1. Por qué

Responde a tres pendientes registrados:

| Pendiente | Origen |
|---|---|
| A1 cumple solo parcialmente: falta volumen y distribución de datos (semilla) | `docs/auditoria-modulo6.md` |
| I-1: en la serie B de S11 la latencia creció a la vez que las filas acumuladas (0 → 79 810), y los dos efectos quedaron confundidos | `docs/resiliencia/matriz-fallos.md` §3; `10-crecimiento-s11/RESULTADOS.md` §4 |
| A4: memoria de la API y consumo base de una JVM sin carga, no medidos | `docs/distribucion/comparacion-distribucion.md` §5 |

## 2. Pregunta

Con la misma carga (operación B, `POST /api/adopciones`, 200 usuarios, 40 s), ¿cambia la latencia cuando la base de datos empieza con 79 810 solicitudes en lugar de vacía? ¿Cuánta memoria y CPU usa la API en reposo y bajo esa carga?

## 3. Semilla (volumen y distribución)

[`semilla.sql`](./semilla.sql), cargada antes de **cada** corrida de la condición "sembrada":

- **Volumen:** 79 810 filas en `solicitud_adopcion` y 79 810 en `etapa_adopcion`, el mismo número con que terminó la serie B de S11.
- **Distribución:** la misma que produce la operación B sin parámetros: 100 % `estado = PENDIENTE`, 100 % `nombre_etapa = SOLICITUD_RECIBIDA`, una etapa por solicitud y fechas consecutivas.
- En la condición "vacía" las dos tablas se vacían (`TRUNCATE … RESTART IDENTITY`) antes de cada corrida.

## 4. Hipótesis (preregistradas)

| Id | Predicción | Se refuta si |
|---|---|---|
| HS1 | Las 79 810 filas iniciales **no** cambian de forma apreciable el p95: la diferencia relativa entre la mediana del p95 "sembrada" y la "vacía" es < 20 % | \|p95(sembrada) − p95(vacía)\| / p95(vacía) ≥ 20 % |
| HS2 | En las dos condiciones, la tasa de fallos es < 1 % | Mediana de fallos ≥ 1 % en alguna condición |

La memoria y la CPU **no** tienen hipótesis: se reportan como mediciones descriptivas para A4.

## 5. Procedimiento ([`ejecutar.sh`](./ejecutar.sh))

1. PostgreSQL (`docker compose up -d postgres_db`) y la API (`mvn spring-boot:run`) arrancan una vez.
2. **Reposo:** 30 s sin carga, muestreando cada segundo la memoria residente (RSS) y la CPU del proceso de la API ([`muestreo_jvm.py`](./muestreo_jvm.py)).
3. Condición **vacía** y después **sembrada**, 4 corridas cada una. En cada corrida:
   - preparar la BD (vaciar o sembrar);
   - ejecutar k6 con el **mismo script de S11** (`10-crecimiento-s11/escenario-crecimiento.js`, `USUARIOS=200`, `OPERACION=adopcion`, 40 s);
   - muestrear RSS y CPU de la API;
   - registrar las filas antes y después y las solicitudes sin etapa.
4. 10 s de pausa entre corridas.

## 6. Tratamiento de los datos

- La corrida 1 de cada condición se **descarta** (calentamiento); las válidas son la 2, la 3 y la 4.
- Por condición se reporta la **mediana** de las válidas de: p50, p95, p99, req/s y tasa de fallos.
- Memoria: RSS medio en reposo y RSS máximo de cada corrida válida. CPU: media en reposo y media de cada corrida válida.
- Las conclusiones separan hechos, inferencias y lo no verificado.

## 7. Límites conocidos

- El orden es fijo: primero "vacía" y luego "sembrada". Un efecto de orden, como una JVM más caliente en la segunda condición, no se controla.
- La API corre con `mvn spring-boot:run` y k6 en un contenedor, en la misma máquina (contenedor Linux). S11 usó la imagen Docker de la API y k6 v2.2.0, así que **los valores absolutos no se comparan con S11**; solo se comparan las dos condiciones entre sí.
- La semilla solo cubre las tablas que existen. Ninguna operación medida lee datos persistidos, así que la semilla solo puede afectar a las escrituras (índices y tamaño de las tablas).
