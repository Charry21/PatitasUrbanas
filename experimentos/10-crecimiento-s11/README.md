# Experimento de crecimiento — Semana 11

> **Estado: preregistro.** Este documento fija el escenario, la hipótesis, el procedimiento y los criterios de decisión **antes** de ejecutar cualquier medición. Los resultados se registran en [RESULTADOS.md](./RESULTADOS.md) en un commit posterior. Las secciones 1 a 6 no se modifican después de ver los datos; cualquier desviación se anota en RESULTADOS.md.

- Fecha del preregistro: 2026-10-16 (America/Bogota)
- Commit del código medido: `fb26713e0fa4c9201038883e36ddf9bd061e97af` (main, merge del PR #65). El experimento no modifica nada en `app/`.
- Rama de trabajo: `experimento/s11-crecimiento`

## 1. Vínculo con la línea base

| Elemento | Línea base (S4/S5) | Este experimento (S11) |
|---|---|---|
| Escenario | Escenario 1 de [dossier/04-escenarios-calidad.md](../../dossier/04-escenarios-calidad.md): búsqueda de mascotas, p95 < 800 ms | El mismo escenario y el mismo umbral |
| Operación | `GET /api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5` | La misma operación (operación A) |
| Carga | 100 req/s constantes, 40 s (`constant-arrival-rate`) | Escalones de 50, 100, 150 y 200 usuarios, 40 s cada uno (`constant-vus`, 1 s de espera entre peticiones de cada usuario) |
| Resultado registrado | Mediana p95 = 2.49 ms, 0 % fallos (corridas 6–8, [01-metodologia-medicion.md](../01-metodologia-medicion.md) §6) | — |

Con 1 s de espera por usuario, el escalón de 100 usuarios produce del orden de 100 req/s, la tasa de la línea base. **No es idéntico**: la línea base usa un modelo abierto (tasa fija) y este experimento un modelo cerrado (usuarios que esperan su respuesta). Además el entorno cambia (§4). Por eso la comparación con la línea base es orientativa, no una medición repetida bajo las mismas condiciones.

**Limitación conocida desde la línea base:** `MascotaController.buscarMascotas` devuelve una cadena fija y **no consulta la base de datos**. La operación A mide la capa HTTP/Spring Boot, no una búsqueda geoespacial.

### Operación B (secundaria, exploratoria)

Como la operación A no toca PostgreSQL, se añade `POST /api/adopciones` (crea una `SolicitudAdopcion` y una `EtapaAdopcion` en una transacción, ver `AdopcionService`). No tiene línea base de la Semana 4 y no forma parte del escenario 1; se reporta aparte y solo como evidencia exploratoria para la Semana 12 (ADR 4, matriz de fallos).

## 2. Pregunta

¿Cómo cambian la latencia (p95), el throughput y los errores de cada operación cuando los usuarios concurrentes pasan de 50 a 100, 150 y 200, y en qué escalón (si alguno) aparece la primera degradación observable?

## 3. Hipótesis y predicciones (preregistradas)

| Id | Operación | Predicción | Se refuta si |
|---|---|---|---|
| H1 | A (buscar) | En los 4 escalones, p95 < 800 ms y tasa de fallos < 1 % | En algún escalón la mediana del p95 de las corridas válidas es ≥ 800 ms, o la mediana de la tasa de fallos es ≥ 1 % |
| H2 | A (buscar) | El throughput crece con los usuarios: en cada escalón, la mediana de req/s es ≥ 90 % del throughput teórico `N / (1 s + latencia media)` | En algún escalón la mediana de req/s es < 90 % del teórico |
| H3 | B (adopción) | En los 4 escalones, p95 < 800 ms y tasa de fallos < 1 % | Igual que H1, aplicado a B |
| H4 | Instrumento | El generador de carga (k6) no se satura: uso medio de CPU de k6 < 80 % de un núcleo en cada corrida válida, y CPU total de la máquina < 90 % | Alguna corrida válida supera cualquiera de los dos límites |

**Razonamiento previo (inferencia, no evidencia):** la operación A es una respuesta estática; la línea base dio p95 de pocos milisegundos a 100 req/s, y 200 req/s sigue siendo poca carga para Tomcat (200 hilos por defecto). La operación B usa el pool de conexiones por defecto de Hikari (10 conexiones) y tiene el log SQL en nivel DEBUG; esperamos que siga bajo el umbral, pero es la operación con más probabilidad de mostrar degradación primero. Toda la máquina tiene 2 vCPU compartidos por k6, la API y PostgreSQL, por eso se mide H4.

**Si H4 se refuta en un escalón**, los resultados de latencia de ese escalón se marcan como *contaminados por el instrumento*: no se usan para afirmar que la API se degradó.

## 4. Condiciones de ejecución

- Máquina: contenedor Linux en la nube (Ubuntu 24.04.5 LTS, kernel 6.18.44, x86_64), **2 vCPU, 7.8 GiB de RAM**. No es el equipo Windows/WSL2 de la línea base.
- Generador de carga, API y base de datos **comparten la misma máquina** (no hay otra disponible).
- Docker Engine 29.8.2. PostgreSQL `postgres:16` con `pg_stat_statements` (como en `docker-compose.yml`). API construida desde `app/` con la variante de Dockerfile que añade las CA del entorno en la etapa de build (`experimentos/spike-s10/build-imagen-api-2026-10-10/intento-3-ca-entorno-completa/`), porque el Dockerfile original no construye detrás del proxy TLS del entorno. La etapa final de la imagen no cambia.
- Contenedores lanzados con `docker run` con las mismas variables que `docker-compose.yml` (mismo motivo que en el registro del spike S10).
- Configuración de la API sin cambios: `ddl-auto=create-drop`, Hikari y Tomcat por defecto, log SQL en DEBUG.
- Semilla de datos: **no aplica**. No hay scripts de seed; las tablas se crean vacías al arrancar la API. En la operación B las filas crecen durante la serie; se registra el conteo después de cada corrida.
- La versión exacta de k6, Java y PostgreSQL se registra en `resultados/entorno.txt` al ejecutar.

## 5. Procedimiento

1. Levantar PostgreSQL y la API; verificar `GET /actuator/health` = `UP`.
2. Para cada operación (A y luego B), ejecutar [`ejecutar.sh`](./ejecutar.sh):
   - reinicia el contenedor de la API (JVM nueva) y espera `UP`;
   - para cada escalón en orden **50 → 100 → 150 → 200**, hace **4 corridas** de 40 s con [`escenario-crecimiento.js`](./escenario-crecimiento.js) y 10 s de pausa entre corridas;
   - durante cada corrida, [`muestreo_cpu.py`](./muestreo_cpu.py) registra cada segundo la CPU total y la de k6, Java y PostgreSQL.
3. Por corrida se guardan: resumen JSON de k6, línea de resumen, stderr, CSV de CPU y una línea en `bitacora.txt` con horas de inicio y fin, código de salida y filas en BD.

## 6. Tratamiento de los datos (fijado antes de medir)

- La **corrida 1 de cada escalón se descarta** (calentamiento). Corridas válidas: 2, 3 y 4 (número impar, como pidió el docente en S5).
- Por escalón se reporta la **mediana** de las 3 corridas válidas de: p50, p95, p99, req/s y tasa de fallos; además los conteos de códigos HTTP por clase (2xx, 4xx, 5xx, sin respuesta).
- CPU: media de las muestras de cada corrida; por escalón se reporta el máximo de esas medias entre las corridas válidas (criterio conservador para H4).
- Throughput teórico de H2: `N / (1 + latencia_media_en_segundos)`.
- Se reportan todas las corridas, incluidas las descartadas, en la tabla completa de RESULTADOS.md.
- Las conclusiones separan **hechos** (lo que dicen los registros), **inferencias** y **lo no verificado**.
