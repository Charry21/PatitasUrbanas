# Autoauditoría del Módulo 6 (A1–A6) — 2026-10-24

Contrastada con los criterios de la auditoría del tutor del Módulo 6 y con la ficha de entregables. Estados: **Cumple**, **Cumple parcialmente** y **No cumple**. Cada fila cita el archivo y la evidencia concreta.

| Criterio | Exigencia del tutor | Estado | Archivo y evidencia |
|---|---|---|---|
| **A1** Mediciones reproducibles | ≥ 3 corridas, descarte de la primera, mediana | **Cumple** | `experimentos/10-crecimiento-s11/RESULTADOS.md` §1–§2: 4 corridas por escalón, se descarta la 1, mediana de las 2–4 |
| | Máquina, duración, usuarios virtuales | **Cumple** | Ídem §1 y `README.md` §4: 2 vCPU, 7.8 GiB; 40 s por escalón; 50/100/150/200 usuarios |
| | Códigos de respuesta | **Cumple** | Ídem §2: 2xx / 4xx / 5xx / sin respuesta por escalón; archivos crudos en `resultados/<operación>/` |
| | Versión del código | **Cumple** | `README.md`: `fb26713`; `resultados/entorno.txt` (SHA-256 del jar) |
| | Volumen y distribución de los datos | **Cumple parcialmente** | No hay semilla: las tablas empiezan vacías y en la serie B crecen de 0 a 79 810 filas (`RESULTADOS.md` §1). Está declarado; una semilla real requiere otro experimento |
| | Reproducibilidad y trazabilidad | **Cumple** | Preregistro `964dd4a` antes de medir; `trazabilidad-analisis.md` (análisis reproducido byte a byte) |
| **A2** Matriz de fallos observados e hipotéticos | Clasificación, evidencia y estado por fila | **Cumple** | `docs/resiliencia/matriz-fallos.md`: 13 filas, 8 observadas (con experimento o archivo citado), 3 hipotéticas y 2 con la consecuencia hipotética |
| | Que una posibilidad no probada no figure como demostrada | **Cumple** | Ídem: F-09, F-10 y F-12 marcadas "Hipotético"; F-07 y F-11 separan lo observado de la consecuencia no probada |
| **A3** Tácticas con evidencia | Cada táctica probada o marcada como propuesta | **Cumple** | `docs/resiliencia/matriz-resiliencia.md`: R-01, R-02, R-03 y R-06 probadas; R-04 y R-05 parciales, con sus reservas; R-07 a R-12 propuestas |
| | Que el resultado corresponda a la prueba | **Cumple** | Cada táctica probada cita su prueba: `experimentos/12-inyeccion-fallos-s12/RESULTADOS.md` (HF1a–HF3, preregistrado en el PR #76 antes de ejecutar), el test de rollback y `verificacion-endpoints.txt` |
| **A4** Alternativas y costos | ≥ 2 alternativas, mismas dimensiones | **Cumple** | `docs/distribucion/comparacion-distribucion.md` §1 y §3: D1, D2 y D3 en 13 dimensiones |
| | Costos | **Cumple parcialmente** | Recursos y esfuerzo estimados, cada uno con su clase (medido, estimado, documentado o pendiente). Precios en COP y memoria: **pendientes** (§5); no se inventaron |
| | Consecuencias positivas y negativas | **Cumple** | Ídem §4 |
| | Supuestos no verificados y condiciones de revisión | **Cumple** | Ídem §2: S1–S5, indicando si se verificó y su condición de revisión |
| **A5** ADR 4 | Título, estado, contexto con evidencia, fuentes, alternativas, costos, decisión, consecuencias, supuestos | **Cumple** | `adr/adr-04-distribucion.md` (Propuesta), con fuentes S11, S12, A2, A3 y A4 |
| | Veredicto **real** del comité | **No cumple todavía** | La sección "Veredicto del comité" está vacía a propósito: se completa solo después de celebrar el mini-comité |
| **A6** Fitness function | Regla ejecutable y decisión que protege | **Cumple** | `docs/fitness/ff-01-fronteras-modulares.md`: ADR-02 y R1–R3; `tools/fitness/fronteras_modulares.py` |
| | Se ejecuta automáticamente en CI | **Cumple** | `.github/workflows/fitness-functions.yml`; ejecuciones `40050755388` (PR #77) y `40050776080` (`main`), ambas *success* |
| | Prueba de violación deliberada que haga fallar la validación | **Cumple** | `tools/fitness/prueba_negativa.sh`: 5 violaciones inyectadas, las 5 fallan; se ejecuta en el mismo job de CI. Además falla sobre `887ccf1` (9 violaciones) |

## Pendientes que dependen del equipo

1. Celebrar el mini-comité del ADR-04 y registrar su veredicto real.
2. Decidir M6-1 a M6-6 en `docs/registro-ia-modulo6.md` y firmarlo.
3. Cotizar los precios y medir la memoria de la API (A4 §5).
4. Si se quiere cerrar el "parcial" de A1: preregistrar una serie con una semilla de volumen y distribución declarados.
