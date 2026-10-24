# Resultados — Inyección de fallos S12

> Preregistro: [README.md](./README.md), fusionado con el PR #76 el **2026-10-24 01:24:37 UTC** (hora del servidor de GitHub). La ejecución empezó a las **01:25:04 UTC**, después del preregistro. Las secciones 1–5 del README no cambian.

## 1. Cómo se obtuvo cada dato

| Dato | Valor |
|---|---|
| Fecha de ejecución | 2026-10-24, 01:25:04Z a 01:33:09Z |
| Código bajo prueba | `14c1d55` (`main`, merge del PR #76). `app/src/main` idéntico al código medido en el spike 1 (`1e522df`) |
| Entorno | [resultados/entorno.txt](./resultados/entorno.txt): Ubuntu 24.04.4 (contenedor Linux, 4 CPU), OpenJDK 21.0.11, Maven 3.9.11, Docker 29.6.2, PostgreSQL 16.15 |
| API | `mvn spring-boot:run`, arrancada una vez y **no reiniciada** durante los 3 ciclos |
| Bitácoras | [resultados/ciclo-1.txt](./resultados/ciclo-1.txt), [ciclo-2.txt](./resultados/ciclo-2.txt), [ciclo-3.txt](./resultados/ciclo-3.txt) |
| Log de la API | [resultados/log-api-extracto.txt](./resultados/log-api-extracto.txt) (líneas WARN y ERROR) |

## 2. Resultados por ciclo

| Ciclo | Línea base | F1 · POST (código, tiempo) | F1 · GET buscar | F1 · health | F2 · primer 201 tras BD `healthy` | HF3 (solicitudes / etapas / sin etapa · 201 acumulados) |
|---|---|---|---|---|---|---|
| 1 | 3×201, 3×200, health 200 UP | 500 (0.04 s), 500 (30.01 s), 500 (30.01 s) | 3×200 (≤ 0.005 s) | 3×503 DOWN (30.0 s cada una) | primer intento, 0.035 s | 4 / 4 / 0 · 4 |
| 2 | ídem | 500 (0.01 s), 500 (30.01 s), 500 (30.01 s) | 3×200 | 3×503 DOWN (30.0 s) | primer intento, 0.056 s | 8 / 8 / 0 · 8 |
| 3 | ídem | 500 (0.01 s), 500 (30.01 s), 500 (30.01 s) | 3×200 | 3×503 DOWN (30.0 s) | primer intento, 0.040 s | 12 / 12 / 0 · 12 |

## 3. Verificación de las hipótesis (criterios del README §2, sin cambios)

| Hipótesis | Criterio de refutación | Resultado |
|---|---|---|
| HF1a: con la BD caída, POST responde 5xx en ≤ 35 s, nunca 2xx | Algún 2xx, > 35 s o sin respuesta | **No refutada.** 9/9 respuestas 500; máximo 30.013 s |
| HF1b: con la BD caída, `/buscar` sigue en 200 | Algún código distinto de 200 | **No refutada.** 9/9 respuestas 200 |
| HF1c: con la BD caída, health = 503 DOWN | Algún código distinto de 503/DOWN | **No refutada.** 9/9 respuestas 503 con `status` DOWN |
| HF2: sin reiniciar la API, POST vuelve a 201 en ≤ 60 s desde BD `healthy` | No vuelve en 60 s | **No refutada.** Recuperación en el primer intento, 0.035–0.056 s |
| HF3: filas = 201 recibidos; 0 solicitudes sin etapa | Cualquier diferencia | **No refutada.** 12 = 12 = 12; 0 sin etapa |

## 4. Conclusión

### Hechos

1. **Con la BD caída, la escritura falla de forma limpia.** `POST /api/adopciones` responde 500 con el cuerpo de error por defecto de Spring. Ninguna solicitud se registró a medias (HF3).
2. **El primer POST tras la caída falla en milisegundos y los siguientes tardan 30 s.** El log muestra que Hikari descarta las conexiones rotas ("Failed to validate connection") y luego espera su `connectionTimeout` de 30 000 ms ("Connection is not available, request timed out after 30000ms").
3. **La operación que no usa la BD no se ve afectada.** `GET /api/mascotas/buscar` respondió 200 en ≤ 5 ms durante la caída.
4. **El health check detecta la caída, pero tarda 30 s en decirlo.** `GET /actuator/health` respondió 503 DOWN, cada vez tras unos 30 s.
5. **La recuperación es automática.** Sin reiniciar la API, el primer POST después de que la BD estuvo `healthy` respondió 201 en < 0.06 s.

### Inferencias (no demostradas)

- Con la configuración por defecto, durante una caída de la BD cada petición de escritura ocupa un hilo de Tomcat hasta 30 s. Con muchas peticiones concurrentes esto podría agotar los 200 hilos por defecto y afectar también a `/buscar`. **No se probó** con carga concurrente.
- Un orquestador o monitor que consulte `/actuator/health` con un tiempo de espera menor que 30 s vería un tiempo de espera agotado, no un 503.

### No verificado

- Caída de la BD **bajo carga** (este experimento envía peticiones de una en una).
- BD lenta, red intermitente, agotamiento del pool sin caída, disco lleno.
- Ejecución con la imagen Docker y en Windows/WSL2.

## 5. Insumos para la Semana 12

- **Matriz de fallos (A2):** filas **observadas** para "BD no disponible" (F1) y "BD vuelve" (F2), con su evidencia.
- **Matriz de resiliencia (A3):** tácticas ya presentes y ahora **probadas**: transacción atómica (HF3), aislamiento de la operación sin BD (HF1b), detección por health check (HF1c) y reconexión automática del pool (HF2). El tiempo de espera de 30 s queda como costo observado.
