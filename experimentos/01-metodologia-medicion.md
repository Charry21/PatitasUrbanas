# Metodología y Resultados de Línea Base (Semana 4)

## 1. Trazabilidad de la Medición
* **Fecha de Ejecución:** 31 de agosto de 2026
* **Versión del Código (Commit Hash):** 8c7b9f58cace81b9a50f157b3fdb85df9c2c27e1
* **Condiciones del Entorno y Hardware:**
  * Sistema Operativo: Windows, Docker Desktop (WSL2).
  * Motor de Base de Datos: PostgreSQL 16 (imagen estándar `postgres:16`, sin extensión PostGIS).
  * Microservicio: Java 21 + Spring Boot 3.3.4.
  * Herramienta de Carga: k6.
  * Fuente de Energía: Equipo conectado a corriente alterna (AC) sin perfiles de ahorro de batería.

## 2. Corrección de auditoría (Semana 5)

**Hallazgo:** una versión previa de este documento describía una base de datos
con extensión PostGIS, índices espaciales (GIST) y una semilla de 5,000
registros con distribución 80/20. Esa infraestructura **nunca existió en el
repositorio** (confirmado por auditoría de `docker-compose.yml`, `pom.xml` y
ausencia de scripts de seed en todo el historial de Git). Se corrige esta
sección para reflejar lo que realmente se midió.

**Lo que realmente se midió:** el endpoint `GET /api/mascotas/buscar`
(`MascotaController.java`), que recibe `lat`, `lng` y `radio` como parámetros
pero **no ejecuta ninguna consulta a la base de datos** — devuelve una
respuesta JSON estática. La medición de S4, por tanto, mide la latencia de
un endpoint HTTP simulado servido por Spring Boot, no el rendimiento de una
consulta espacial en PostgreSQL/PostGIS.

## 3. Coherencia Escenario - Script
* **Escenario Definido (Semana 3):** Rendimiento en consultas de geolocalización de mascotas bajo una carga de 100 req/s.
* **Operación Medida (Semana 4):** El script inyecta tráfico contra el endpoint `/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5`, que responde de forma simulada sin consultar la base de datos. Se utiliza `constant-arrival-rate` para garantizar un volumen sostenido de 100 peticiones por segundo durante 40 segundos.
* **Nota de alcance:** esta medición valida la latencia de la capa HTTP/Spring Boot bajo carga, no el rendimiento de una consulta geoespacial real. La validación de una consulta PostGIS real queda pendiente para cuando exista la capa de persistencia correspondiente.

## 4. Protocolo de 3 Corridas y Tratamiento Estadístico
Se descarta la primera corrida por efectos de calentamiento (warm-up) de la JVM. La métrica final es la mediana de las corridas válidas 2 y 3, garantizando correspondencia estricta con los archivos `.txt` adjuntos.

* **Corrida 1 (Descartada - Warm-up):** 4000 iteraciones, 100% éxito. p95 = 2.85 ms.
* **Corrida 2 (Válida):** 4000 iteraciones, 100% éxito. p95 = 1.82 ms.
* **Corrida 3 (Válida):** 4001 iteraciones, 100% éxito. p95 = 1.80 ms.

**Estadística Final Reportada:**
* **Mediana del p95 (Corridas Válidas):** 1.81 ms.
* **Códigos HTTP verificados:** 100% de respuestas HTTP 200 (0 fallos).

## 5. Contraste con la Hipótesis de S3
* **Hipótesis Estipulada (Semana 3):** p95 < 800 ms bajo carga de 100 req/s en búsqueda espacial.
* **Evidencia Medida (Semana 4):** La mediana p95 obtenida es de 1.81 ms, **medida sobre el endpoint simulado**, no sobre una consulta espacial real contra PostgreSQL/PostGIS.
* **Conclusión:** El sistema cumple el umbral de rendimiento para la carga HTTP del endpoint tal como existe hoy. Esta conclusión **no puede extenderse** a "el sistema cumple el umbral en una búsqueda geoespacial real", porque esa capa (PostGIS, persistencia, datos sembrados) no está implementada todavía.

## 6. Actualización S5: segunda ronda de medición (cumplimiento de criterio de 3 corridas válidas)

El docente confirmó que el protocolo exige un número **IMPAR** de corridas válidas (3 o más), además de las corridas descartadas por warm-up. La sección 4 original solo reportaba 2 corridas válidas.

Las cinco corridas de esta segunda ronda se ejecutaron el 12 de septiembre de 2026 contra el endpoint `GET /api/mascotas/buscar`, usando el mismo script `experimentos/escenario-rendimiento.js`, con una tasa constante de 100 req/s durante 40 segundos.

| Corrida | p95 | Iteraciones | Fallos HTTP | Estado | Motivo |
|---|---:|---:|---:|---|---|
| 4 | 6.5 ms | 3999 | 0% | Descartada | Se ejecutó justo después de `docker compose up -d`, que reconstruyó la imagen de la API y reintrodujo el efecto de arranque en frío (warm-up de JVM). |
| 5 | 3.12 ms | 3999 | 0% | Descartada | Todavía muestra decaimiento del warm-up; no se había estabilizado. |
| 6 | 2.49 ms | 4001 | 0% | Válida | Corrida válida de la ronda estable. |
| 7 | 2.52 ms | 4001 | 0% | Válida | Corrida válida de la ronda estable. |
| 8 | 2.08 ms | 4000 | 0% | Válida | Corrida válida de la ronda estable. |

Esta ronda **no se combina** con las corridas 2 y 3 de la sección 4. Aquellas corresponden a la Semana 4, se ejecutaron en otra sesión y posiblemente bajo condiciones de entorno distintas. Por ello, esta segunda ronda se reporta como una ronda de medición independiente y completa, sin mezclar condiciones distintas.

**Nota honesta:** en esta ronda el warm-up tomó 2 corridas en estabilizarse (corridas 4 y 5), no 1 como en la medición original de la Semana 4. Esta es una observación válida, no un error que deba ocultarse.

**Mediana final de esta ronda:** 2.49 ms (corridas válidas 6, 7 y 8).

La mediana final de 2.49 ms sigue muy por debajo del umbral de la hipótesis de S3 (p95 < 800 ms). La conclusión de la sección 5 se mantiene sin cambios: el sistema cumple el umbral para el endpoint simulado, no para una búsqueda geoespacial real.

## 7. Aclaración de auditoría (2026-10-24)

Esta sección se añade sin modificar las anteriores. Recoge los hallazgos A1–A4 de [`11-auditoria-reproducibilidad.md`](./11-auditoria-reproducibilidad.md) §2.

| Afirmación de este documento | Aclaración verificada con Git | Efecto |
|---|---|---|
| §1 "Fecha de ejecución: 31 de agosto de 2026" (ronda 1, corridas 1–3) | Los archivos de las corridas 1–3 ya estaban en GitHub el **2026-08-28 a las 20:49:10 UTC** (PR #7). La ejecución fue anterior a esa hora; la fecha exacta no está registrada. | La fecha de §1 no es correcta. |
| §1 "Versión del código: `8c7b9f58…`" (ronda 1) | `8c7b9f5` es posterior a los resultados (`789ed21`) y no contiene `/api/mascotas/buscar`. Ningún commit contiene ese endpoint antes de `22b0ac0` (2026-09-04). | El código que sirvió la ronda 1 **no está versionado**. |
| §3 "Operación medida: `/api/mascotas/buscar`" (ronda 1) | En `789ed21` el script versionado llamaba a `/actuator/health`. Indicio a favor de `/api/mascotas/buscar`: ~175 B por respuesta, igual que en la ronda 2 y que la respuesta actual de ese endpoint (`/actuator/health`: 438 B). | Operación **no verificable por Git**; el indicio es compatible con lo declarado, pero no lo demuestra. |
| §6 ronda 2 (corridas 4–8), sin hash | El código y el script de la ronda 2 están en `1ac4c37` (PR #35, fusionado el 2026-09-12 17:34:18 UTC). El procedimiento se reprodujo sobre ese commit (`auditoria-reproducibilidad/k6-ronda2-1ac4c37/`). | Ronda 2 **identificable y reproducible**. |

**Decisión del equipo (2026-10-24):** la **ronda 2** (corridas 6–8, commit `1ac4c37`) es la evidencia de línea base que se cita en adelante. La ronda 1 se conserva como registro histórico, con los límites de esta tabla, y no se usa para sostener afirmaciones.

Los valores transcritos en §4 y §6 coinciden con los archivos originales; esta aclaración no cambia ningún número.
