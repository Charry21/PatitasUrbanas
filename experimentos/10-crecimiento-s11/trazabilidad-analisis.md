# Trazabilidad del análisis — Experimento de crecimiento S11

> Registro añadido el 2026-10-23, después de la auditoría de la Semana 11. Responde a los dos puntos marcados como *parciales*: (1) que el script de análisis se incorporó después de iniciar la primera corrida, y (2) que el orden temporal debe poder verificarse.
>
> **Este documento no cambia** las hipótesis, los criterios, el tratamiento de datos ni los resultados de [README.md](./README.md) y [RESULTADOS.md](./RESULTADOS.md). Compara el código con las reglas que ya estaban fijadas y declara las diferencias encontradas.

## 1. Secuencia temporal verificable

Hora de Bogotá (UTC−5), 2026-10-16.

| Hora | Evento | Evidencia |
|---|---|---|
| 18:49:48 | Preregistro: escenario, hipótesis H1–H4, procedimiento, reglas de análisis (§6), script de carga, orquestador y muestreo de CPU | commit `964dd4a` |
| 18:55:52 | Preregistro fusionado en `main` | merge `ab53f25`, [PR #66](https://github.com/Charry21/PatitasUrbanas/pull/66) |
| 19:08:31 | Desviaciones de construcción registradas | commit `c5ed512`, [entorno/desviaciones.md](./entorno/desviaciones.md) |
| 19:08:51 | Inicio de la primera corrida (`buscar`, u50-c1) | [resultados/buscar/bitacora.txt](./resultados/buscar/bitacora.txt): `2026-10-17T00:08:51Z` |
| 19:10:50 | Script de análisis `analizar.py` | commit `be20d16` |
| 19:36:55 | Fin de la última corrida (`adopcion`, u200-c4) | [resultados/adopcion/bitacora.txt](./resultados/adopcion/bitacora.txt): `2026-10-17T00:36:55Z` |
| 19:41:19 | Resultados e informe | commit `3c980e7` |
| 19:43:27 | Resultados fusionados en `main` | merge `f0c4ea5`, [PR #67](https://github.com/Charry21/PatitasUrbanas/pull/67) |

- Las horas de los commits las asigna la máquina de quien los crea; no son una prueba independiente. La hora de fusión del **PR #66**, registrada por GitHub, es la evidencia independiente de que el preregistro estaba en `main` antes de la primera corrida.
- `README.md` solo tiene el commit `964dd4a` (`git log -- experimentos/10-crecimiento-s11/README.md`): no se modificó después de medir.
- `analizar.py` llegó 1 min 59 s después de iniciar la primera corrida y antes de terminar la serie.
- `analizar.py` **se modificó una vez después de medir**, en `3c980e7` (commit de resultados). El cambio está solo en la función `graficar`: añade "peor corrida" al título del panel de CPU y quita las etiquetas numéricas del panel de throughput, donde las dos series se superponen. Las líneas 1–108, que calculan medianas, CPU, teórico y veredictos, son idénticas en `be20d16` y `3c980e7` (`git diff be20d16 3c980e7 -- experimentos/10-crecimiento-s11/analizar.py`). Este cambio no estaba registrado en RESULTADOS.md; se declara aquí.

## 2. Reglas del §6 frente a su implementación en `analizar.py`

Archivo revisado: `analizar.py` en `main` (`3c980e7`, SHA-256 `7986d9fa…e53d`). Las líneas citadas (1–108) son idénticas a las de la primera versión, `be20d16` (SHA-256 `8078aed3…cea5`).

| # | Regla preregistrada (README §3 y §6) | Implementación | ¿Coincide? |
|---|---|---|---|
| R1 | Se descarta la corrida 1 de cada escalón; las válidas son 2, 3 y 4 | `VALIDAS = [2, 3, 4]` (l. 16); `estado` válida/descartada (l. 41) | Sí |
| R2 | Por escalón, mediana de las 3 válidas de p50, p95, p99, req/s y tasa de fallos | `st.median` sobre las válidas (l. 61–68) | Sí |
| R3 | Conteo de códigos HTTP por clase (2xx, 4xx, 5xx, sin respuesta) | Contadores de k6 por corrida (l. 46–47); suma de las 3 válidas (l. 69–70) | Sí. El §6 no fija si es suma o mediana; RESULTADOS §2 declara que es la suma |
| R4 | CPU: media de las muestras de cada corrida; por escalón, el máximo de esas medias | Media por corrida (l. 31–33); máximo entre válidas (l. 71–72) | **Parcial**: el script excluye muestras (ver D-A1) |
| R5 | Throughput teórico de H2: `N / (1 + latencia_media_en_segundos)` | `n / (1 + lat_media_mediana_ms / 1000)` (l. 73) | Sí, con una interpretación (ver D-A2) |
| R6 | H1 y H3 se refutan si la mediana del p95 ≥ 800 ms o la mediana de fallos ≥ 1 % en algún escalón | `p95 < 800 and fallos < 1` (l. 75); veredicto por escalón (l. 83–92) | Sí |
| R7 | H2 se refuta si req/s < 90 % del teórico en algún escalón | `rps_pct_teorico >= 90` (l. 76) | Sí |
| R8 | H4 se refuta si en alguna corrida válida k6 ≥ 80 % de un núcleo o la máquina ≥ 90 % | `LIM_K6 = 80`, `LIM_TOTAL = 90` (l. 19–20); máximo de las medias de las válidas (l. 77, 93–94) | Sí: tomar el máximo de las medias equivale a "en alguna corrida válida" |
| R9 | Se reportan todas las corridas, incluidas las descartadas | `corridas.csv` incluye las 32 corridas (l. 60, 80) | Sí |
| R10 | Conclusiones separadas en hechos, inferencias y no verificado | No es código: [RESULTADOS.md §4](./RESULTADOS.md) | Sí |

## 3. Diferencias encontradas entre el código y el §6

Estas diferencias no se declararon en `entorno/desviaciones.md` ni en RESULTADOS.md. Se registran ahora, **sin cambiar el criterio ni los resultados publicados**. D-A1 quedó además declarada como desviación metodológica en el anexo de [RESULTADOS.md](./RESULTADOS.md), como parte de la interpretación oficial del informe.

| Id | Diferencia | Efecto medido |
|---|---|---|
| D-A1 | El §6 dice "media de las muestras de cada corrida". `analizar.py` (l. 29–30) descarta las muestras con `t_s < 2` (primer segundo, arranque de k6) y con `t_s > 41` (después de los 40 s del escalón): usa 38–39 de 40–41 muestras por corrida | Recalculado con **todas** las muestras: k6 máx. 14,6 % (publicado: 15,3 %) y máquina máx. 37,9 % (publicado: 38,5 %). El filtro da valores **algo mayores**, es decir, más conservadores. El veredicto de H4 no cambia. Incluso con el pico de un solo segundo, k6 llega a 20,9 % y la máquina a 52,5 %, lejos de 80 % y 90 % |
| D-A2 | El §6 no especifica qué "latencia media" usar para el teórico de H2. El script usa la mediana de las latencias medias de las 3 corridas válidas | Mínimo publicado: 98,6 % del teórico, 8,6 puntos por encima del umbral. Cualquier variación razonable de esta elección deja el veredicto igual |
| D-A3 | El script marca un escalón como incompleto si tiene menos de 3 corridas válidas (l. 62–64). No está en el §6 | No se activó: los 8 escalones tienen sus 3 corridas válidas |

## 4. Reproducción del análisis

El 2026-10-23 se ejecutaron, con Python 3.13.17 y sobre una copia de `experimentos/10-crecimiento-s11/` en `main` (`f0c4ea5`), las **dos versiones** del script: la de `main` (`3c980e7`) y la primera (`be20d16`, recuperada con `git show`). Ambas generan archivos **idénticos byte a byte** a los publicados:

| Archivo | SHA-256 |
|---|---|
| `resultados/corridas.csv` | `b5b017695e634c18c4cd720dc0fec218a29af8a34632a239134a8f5aab19759e` |
| `resultados/escalones.csv` | `4921045ff4d75471c7440227e57722bb066feb64d3d8211b5308ed42a58e7df4` |
| `resultados/verificacion-hipotesis.txt` | `4186304c2e7d968c444a62946c5cfd3751928affc35053d79488289cfa499577` |

Esto muestra que los resultados publicados salen del script y de los datos crudos versionados. No vuelve a ejecutar las corridas de carga.

## 5. Comparabilidad con la línea base (se mantiene)

Como declara el preregistro (§1), este experimento **no es una réplica** de la línea base S4/S5:

- el modelo de carga es cerrado (usuarios con 1 s de espera), no abierto (100 req/s fijas);
- la máquina es un contenedor Linux de 2 vCPU compartido por k6, la API y PostgreSQL, no el equipo Windows/WSL2;
- la operación A devuelve una cadena fija y no consulta PostgreSQL.

La comparación con la línea base es orientativa. Los resultados no son evidencia del rendimiento de una búsqueda geoespacial real.

## 6. Conclusión

- Las reglas de análisis estaban fijadas antes de medir (§6, `964dd4a`, PR #66).
- `analizar.py` aplica esas reglas, con tres diferencias (D-A1 a D-A3) que no modifican ningún veredicto. D-A1 es la única que cambia valores publicados, y los cambia en la dirección conservadora.
- El único cambio al script después de medir fue cosmético (gráfica) y no altera ningún resultado: ambas versiones reproducen los archivos publicados.
- No hay evidencia de que los criterios se cambiaran después de ver resultados.
