# Costo de la capa de seguridad sobre el p95 — Semana 13

> **Estado: preregistro.** Este documento fija las condiciones, las hipótesis, el procedimiento y los criterios **antes** de medir. Los resultados se registran en `RESULTADOS.md` en un commit posterior. Las secciones 1 a 6 no se modifican después de ver los datos; cualquier desviación se anota en `RESULTADOS.md`.

- Fecha del preregistro: 2026-11-05 (America/Bogota)
- Rama de trabajo: `experimento/s13-s14-seguridad-operacion`
- Lo prepara y lo ejecuta la IA (Claude). El equipo todavía no lo ha revisado.

## 1. Por qué hace falta construir algo para medir

`main` **no tiene capa de seguridad**: no hay Spring Security, ni JWT, ni TLS (`app/pom.xml`; nota de auditoría del escenario 2 en `dossier/04-escenarios-calidad.md`). Sin capa no hay nada que comparar. Por eso se construye una capa candidata en una rama de código aparte. Esa capa **no es una decisión del equipo**: es la alternativa que se mide para que ADR-05 pueda decidir con datos.

## 2. Condiciones comparadas

| Id | Condición | Qué contiene | Código |
|---|---|---|---|
| S | Sin capa | `main` sin cambios | `3f4b124` |
| C | Capa de aplicación | S + Spring Security como servidor de recursos JWT: valida RS256, emisor, audiencia, caducidad y el permiso `adopciones:escribir`; registra en el log cada acceso denegado | Hash registrado en `resultados/entorno.txt` |
| T | Capa + TLS | C + proxy inverso Caddy que termina TLS delante de la API | El mismo jar de C |

Entre S y C solo cambia la capa. El resto de la configuración es igual a la de S11: `ddl-auto=create-drop`, Hikari y Tomcat por defecto, y log SQL en DEBUG.

## 3. Operaciones y carga

| Operación | Petición | Qué mide |
|---|---|---|
| `buscar` | `GET /api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5`, sin token. Es pública en la capa candidata | La cadena de filtros, sin validar un token |
| `adopcion` | `POST /api/adopciones` con `Authorization: Bearer <token>`. Se envía **la misma cabecera en S, C y T** | La cadena de filtros y la validación RS256, con escritura en BD |
| `sin_token` | `POST /api/adopciones` sin token. **Solo en C** | El rechazo: 401 y registro en el log (escenario 2) |

Carga: **200 usuarios**, 40 s por corrida y 1 s de espera, igual que el escalón más alto de S11. Se reutiliza el modelo de `escenario-crecimiento.js`.

**Limitación que ya se conoce:** `/buscar` es simulado y no consulta la BD. Este experimento mide el costo de la capa, no el de una búsqueda real.

## 4. Hipótesis (preregistradas)

Δ es la diferencia entre las medianas del p95 de dos condiciones, para la misma operación.

| Id | Predicción | Se refuta si |
|---|---|---|
| HC1 | En C y en T, `buscar` y `adopcion` cumplen p95 < 800 ms y fallos < 1 % | La mediana de alguna celda incumple alguno de los dos límites |
| HC2 | Δ(C − S) ≤ 10 ms en `buscar` y en `adopcion` | Δ > 10 ms en alguna operación |
| HC3 | Δ(T − C) ≤ 15 ms en `buscar` y en `adopcion` | Δ > 15 ms en alguna operación |
| HC4 | El instrumento no se satura: CPU media de k6 < 80 % de un núcleo y CPU total < 90 % en cada corrida válida | Alguna corrida válida supera un límite |
| HC5 | En `sin_token`, el 100 % de las respuestas son 401, con p95 < 500 ms, y el log tiene una línea de auditoría por cada 401 | Hay una respuesta distinta de 401, o p95 ≥ 500 ms, o los conteos no coinciden |

**Razonamiento previo (inferencia, no evidencia):** validar RS256 y pasar por los filtros debería costar poco comparado con la escritura en BD; TLS añade un proceso más en una máquina de 2 vCPU. Los umbrales de 10 y 15 ms son una elección de este preregistro, no un requisito del curso.

**Si HC4 se refuta en una corrida**, esa celda se marca como *contaminada por el instrumento* y no se usa para afirmar un costo.

## 5. Procedimiento

`ejecutar.sh` corre **6 bloques** en este orden: `S C T T C S`. El orden en espejo reparte entre las condiciones cualquier deriva de la máquina.

En cada bloque:

1. Arranca la API de esa condición en una JVM nueva, con tablas vacías, y espera `UP`.
2. Para cada operación, hace **4 corridas** de 40 s con 10 s de pausa, y muestrea la CPU cada segundo con `experimentos/10-crecimiento-s11/muestreo_cpu.py`.
3. Guarda el resumen JSON de k6, la salida, el CSV de CPU y una línea en `bitacora.txt`.

Durante las corridas **no se compila ni se ejecuta nada más** en la máquina.

## 6. Tratamiento de los datos (fijado antes de medir)

- La **corrida 1 de cada operación en cada bloque se descarta** (calentamiento). Corridas válidas: 2, 3 y 4 de cada bloque; en total, 6 por celda.
- Por celda (condición × operación) se reporta la **mediana** de las 6 corridas válidas de p50, p95, p99, req/s y tasa de fallos.
- **Ruido:** para cada celda se calcula la diferencia absoluta entre la mediana del p95 de sus dos bloques. El ruido de una comparación es el mayor de los dos valores.
- **Comparación concluyente solo si** HC4 no se refuta en ninguna de las dos celdas **y** |Δ| es mayor que el ruido. Si no, se reporta como **no concluyente**: la diferencia no se distingue de la variación entre bloques.
- Se reportan todas las corridas, incluidas las descartadas.
- Las conclusiones separan hechos, inferencias y lo no verificado.

## 7. Condiciones de ejecución

- Máquina: contenedor Linux en la nube, 2 vCPU y 7.8 GiB, el mismo tamaño que en S11. El generador, la API, la BD y el proxy **comparten la máquina**.
- La versión exacta de k6, Java, PostgreSQL, Caddy, Docker y el hash de cada jar se guardan en `resultados/entorno.txt`.
- Los números absolutos **no predicen producción**. Solo sirven para comparar las condiciones entre sí en esta máquina.
