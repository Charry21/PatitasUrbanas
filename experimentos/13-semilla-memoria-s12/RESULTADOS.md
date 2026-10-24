# Resultados — Semilla de datos y memoria de la API (S12)

> Preregistro: [README.md](./README.md), fusionado con el PR #79 el **2026-10-24 01:51:58 UTC** (servidor de GitHub). La primera corrida empezó a las **01:53:10 UTC**, después del preregistro. Las secciones 1–7 del README no cambian.

## 1. Cómo se obtuvo cada dato

| Dato | Valor |
|---|---|
| Fecha | 2026-10-24, 01:52:37Z (entorno y reposo) a 01:59:57Z |
| Código | `1a57451` (`main`, merge del PR #79); `app/src/main` idéntico al medido en el spike 1 |
| Entorno | [resultados/entorno.txt](./resultados/entorno.txt): contenedor Linux con 4 CPU, OpenJDK 21.0.11, k6 v2.3.0 (contenedor), PostgreSQL 16.15. API con `mvn spring-boot:run` |
| Carga | `10-crecimiento-s11/escenario-crecimiento.js`, `USUARIOS=200`, `OPERACION=adopcion`, 40 s |
| Corridas | 2 condiciones × 4 corridas; se descarta la 1 de cada condición. Todas terminaron con código 0 |
| Archivos | `resultados/bitacora.txt` (filas antes/después y solicitudes sin etapa por corrida); `<condición>-c<n>.txt` (resumen de k6); `<condición>-c<n>.jvm.csv` y `reposo.csv` (RSS y CPU de la API por segundo); `analisis.txt` (salida de [`analizar.py`](./analizar.py)) |

## 2. Desviación

**D1 — No se guardaron los JSON de resumen de k6.** El contenedor de k6 no tuvo permiso para escribir en la carpeta montada (`permission denied`, en `resultados/*.err`). Por eso:

- **Qué se perdió:** el conteo de códigos HTTP por clase que S11 guardaba en el JSON.
- **Con qué se sustituye:**
  - la línea de resumen de k6 (`.txt`), que contiene p50, p95, p99, req/s, máximo y fallos y sale de la misma función `handleSummary`;
  - la bitácora, donde las filas insertadas en cada corrida (8 000, o 7 979 en la descartada) coinciden con las peticiones y hay 0 % de fallos, así que todas las respuestas fueron 2xx.
- **Cómo se registra en el análisis:** `analizar.py` lee el `.txt` en lugar del JSON. Ese cambio se hizo **después** de ver los datos, solo para leer la fuente disponible; no cambia ninguna regla del §6.
- **Las mediciones no se repitieron.**

## 3. Resultados (mediana de las corridas válidas 2, 3 y 4)

| Condición | Filas al empezar | p50 (ms) | p95 (ms) | p99 (ms) | req/s | Fallos | RSS máx. de la API (MiB) | CPU media de la API (% de un núcleo) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Vacía | 0 | 6.34 | **31.95** | 107.57 | 196.86 | 0 % | 311.7 | 36.2 |
| Sembrada | 79 810 | 6.60 | **27.76** | 73.05 | 197.05 | 0 % | 313.2 | 35.9 |

**Reposo (30 s sin carga):** RSS de la API **227.4 MiB** y CPU **0.30 %** de un núcleo.

Todas las corridas, incluidas las descartadas: [resultados/analisis.txt](./resultados/analisis.txt). Los p95 válidos de la condición vacía van de 20.21 a 33.35 ms y los de la sembrada de 24.25 a 28.13 ms.

**Integridad de los datos:** en las 8 corridas, las filas después = filas antes + peticiones, y hay 0 solicitudes sin etapa (`bitacora.txt`).

## 4. Verificación de las hipótesis (criterios del README §4, sin cambios)

| Hipótesis | Criterio de refutación | Resultado |
|---|---|---|
| HS1: la semilla no cambia el p95 de forma apreciable | \|diferencia relativa\| ≥ 20 % | **No refutada.** −13.1 % (la sembrada es más rápida) |
| HS2: fallos < 1 % en las dos condiciones | Mediana ≥ 1 % | **No refutada.** 0 % y 0 % |

## 5. Conclusión

### Hechos
1. Con 79 810 filas iniciales, la escritura **no** fue más lenta que con la base vacía. La diferencia de p95 (−13.1 %) está dentro de la variación entre corridas de la misma condición (20.21–33.35 ms en la vacía).
2. Con 200 usuarios escribiendo, la API ocupó como máximo 313 MiB de memoria residente y ~36 % de un núcleo; en reposo, 227 MiB y 0.3 %.
3. Ninguna corrida tuvo fallos ni escrituras a medias.

### Inferencias (no demostradas)
- En el rango probado (hasta ~88 000 filas), el **volumen acumulado no explica** la degradación de cola observada en la serie B de S11 (F-05). Quedan como candidatos el pool de conexiones, el log SQL en DEBUG y la CPU compartida (S11 §4).
- La memoria de la API se mantiene en el orden de 0.3 GiB con esta carga, así que un contenedor de 1 GiB tendría margen. **No se probó** con más carga ni durante más tiempo.

### No verificado
- Volúmenes mayores de ~88 000 filas, o una distribución con varios estados y etapas.
- El efecto del orden: la condición sembrada siempre se ejecutó después de la vacía.
- La memoria durante periodos largos (fugas, recolección de basura) y con la imagen Docker.

## 6. Qué alimenta

- **A1** (`docs/auditoria-modulo6.md`): existe ahora una medición con semilla de volumen y distribución declarados.
- **I-1 y F-05** (`docs/resiliencia/matriz-fallos.md`): las filas acumuladas, hasta ~88 000, quedan descartadas como explicación.
- **A4** (`docs/distribucion/comparacion-distribucion.md`): memoria y consumo base de la API medidos.
