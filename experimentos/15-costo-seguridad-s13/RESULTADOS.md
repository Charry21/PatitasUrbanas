# Resultados — Costo de la capa de seguridad sobre el p95

Preregistro: [README.md](./README.md), commit `0e9c109` y PR #82, abierto el 2026-11-06 a las 01:52:53 UTC. La primera corrida empezó a las 01:59:52 UTC. Las secciones 1 a 6 del README no cambian.

Ejecutado por la IA; pendiente de revisión del equipo.

## 1. Cómo se obtuvo cada dato

| Dato | Valor |
|---|---|
| Fecha | 2026-11-06, 01:59:43 a 02:49:30 UTC (2026-11-05 en Bogotá) |
| Código | S: `3f4b124`. C y T: `07c8cac` en `feat/s13-capa-seguridad` |
| Entorno | [resultados/entorno.txt](./resultados/entorno.txt): 2 vCPU, 7.8 GiB, Docker 29.9.2, k6 v2.3.0, PostgreSQL 16.15, Caddy 2.11.9 |
| Carga | 200 usuarios, 40 s, 1 s de espera |
| Corridas | 56 en total, 42 válidas y 445 695 peticiones. Todas con código de salida 0, sin 5xx ni peticiones sin respuesta |
| Archivos | [`corridas.csv`](./resultados/corridas.csv), [`celdas.csv`](./resultados/celdas.csv), [`analisis.txt`](./resultados/analisis.txt), [`bitacora.txt`](./resultados/bitacora.txt) y `bloque-*/` |

## 2. Resultados (mediana de 6 corridas válidas, 200 usuarios)

| Condición | Operación | p50 (ms) | p95 (ms) | p99 (ms) | req/s | Fallos | p95 por bloque (ms) | Rango del p95 por corrida (ms) | CPU máx. de la API (% de un núcleo) |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| S | `buscar` | 1.85 | **16.11** | 39.19 | 197.98 | 0 % | 18.00 / 14.90 | 9.43–24.68 | 13.0 |
| C | `buscar` | 2.06 | **21.34** | 46.38 | 197.80 | 0 % | 24.19 / 20.12 | 14.08–25.57 | 19.1 |
| T | `buscar` | 2.84 | **26.66** | 86.76 | 196.32 | 0 % | 26.31 / 36.88 | 19.06–38.16 | 17.3 |
| S | `adopcion` | 4.98 | **44.20** | 112.61 | 196.09 | 0 % | 46.71 / 39.36 | 36.96–59.75 | 19.9 |
| C | `adopcion` | 5.73 | **53.92** | 134.37 | 195.08 | 0 % | 57.04 / 50.80 | 41.56–59.59 | 33.9 |
| T | `adopcion` | 6.58 | **55.02** | 227.09 | 192.94 | 0 % | 52.20 / 56.33 | 38.37–69.27 | 32.7 |
| C | `sin_token` | 2.05 | **17.44** | 46.83 | 198.02 | 0 % como 401 esperado | 18.23 / 14.08 | 12.38–26.44 | 9.7 |

## 3. Comparaciones (reglas de README §6)

| Comparación | Operación | Δ p95 (ms) | Ruido (ms) | Instrumento | ¿Concluyente según §6? |
|---|---|---:|---:|---|---|
| C − S | `buscar` | +5.23 | 4.07 | Bien | Sí |
| C − S | `adopcion` | +9.72 | 7.35 | Bien | Sí |
| T − C | `buscar` | +5.32 | 10.57 | Bien | **No** |
| T − C | `adopcion` | +1.10 | 6.24 | Bien | **No** |

## 4. Verificación de las hipótesis

| Hipótesis | Resultado |
|---|---|
| HC1: p95 < 800 ms y fallos < 1 % en C y T | **No refutada.** Máximo: 55,02 ms y 0 % |
| HC2: Δ(C − S) ≤ 10 ms | **No refutada**, por poco en escritura: +5,23 y +9,72 ms |
| HC3: Δ(T − C) ≤ 15 ms | **No refutada**, pero **no concluyente**: +5,32 y +1,10 ms, por debajo del ruido |
| HC4: instrumento sin saturar | **No refutada.** k6 máx. 13,4 % de un núcleo y CPU total máx. 44,4 % |
| HC5: `sin_token` | **No refutada.** 64 000 peticiones, 64 000 respuestas 401, 64 000 líneas de auditoría y p95 de 17,44 ms frente a 500 ms |

## 5. Conclusión

### Hechos

1. Con la capa, el p95 sigue muy lejos de 800 ms en las dos operaciones, sin fallos, a unas 196 req/s.
2. La mediana sube unos 5 ms en `buscar` y unos 10 ms en `adopcion`.
3. **Los rangos por corrida se solapan mucho:** S y C comparten buena parte de sus valores. Esas diferencias pasan la regla de §6, pero son **débiles**: la variación entre corridas de una misma condición es mayor que el efecto.
4. El costo de TLS en el p95 **no se distingue del ruido**.
5. **La cola sí se mueve:** el p99 de `adopcion` pasa de 112,61 ms (S) a 134,37 ms (C) y a 227,09 ms (T). Las hipótesis no cubrían el p99, así que esto es una observación, no una prueba.
6. La CPU máxima de la API en `adopcion` sube de 19,9 % a 33,9 % de un núcleo con la capa.
7. En todos los casos, las corridas 2 a 4 tienden a mejorar dentro del bloque: el calentamiento dura más que la corrida descartada.
8. Escenario 2: el 100 % de los intentos sin token se bloqueó con 401 y dejó una línea de auditoría.

### Inferencias

- En esta máquina, el costo de la capa es pequeño frente al umbral de 800 ms. La decisión de ADR-05 no depende de la latencia.
- El costo más claro está en la **CPU**, no en el p95. Si el servidor tiene 1 vCPU, como en A4, conviene repetir la medición allí.
- El aumento del p99 con TLS merece una repetición: con estos datos no se puede atribuir a TLS ni descartar el ruido.

### Lo no verificado

- Una búsqueda real: `/buscar` es simulado.
- Datos reales, red real y un cliente remoto: con todo en la misma máquina, TLS no incluye latencia de red.
- Un emisor real de tokens.
- El código final de la rama (`94f2acf`), que añade la regla de `/error` y el endurecimiento. Esos cambios solo afectan a respuestas de error y a configuración, pero **no se volvió a medir**.
- El costo con 1 vCPU.

## 6. Desviaciones

| Id | Qué pasó | Efecto |
|---|---|---|
| D1 | El preregistro decía que durante las corridas no se ejecutaría nada más. Se hicieron 5 s de `git commit` y `git push` a las 02:08:12–02:08:17 UTC, dentro de la corrida válida `C/buscar-c2` del bloque 2 | Esa corrida dio p95 de 24,19 ms, y la misma corrida del bloque 5 dio 22,56 ms; CPU total de 19,5 % frente a 18,7 %. No se ve efecto, y no se repitió |
| D2 | Durante la serie también se hicieron operaciones ligeras: escribir archivos, `git log`, `tail` y consultas a la API de GitHub. No se compiló nada ni se usó Docker | No se puede descartar un efecto mínimo. La CPU total máxima fue de 44,4 % |

Revisión pendiente del equipo.
