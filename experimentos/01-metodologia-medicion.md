# Metodología y Resultados de Línea Base (Semana 4)

## 1. Trazabilidad de la Medición
* **Fecha de Ejecución:** 28 de agosto de 2026
* **Versión del Código (Commit Hash):** 4d13ad35b2b0eaa8a2938d05b28857d8c75ff697
* **Condiciones del Entorno:** Windows, Docker Desktop (WSL2), PostgreSQL 16, Java 21 + Spring Boot 3.3.4, k6.

## 2. Fase Exploratoria Inicial (Trazabilidad)
Se conserva el registro de la prueba exploratoria de 50 segundos con 20 Usuarios Virtuales (VUs) escalonados.
* **Carga real aplicada:** ~16.17 req/s (809 iteraciones).
* **Latencia:** p95 = 4.33 ms.

## 3. Medición de Línea Base Formal (100 req/s)
Para emparejar la carga con el entorno definido en el escenario de la Semana 3, se configuró el script de k6 utilizando el ejecutor `constant-arrival-rate`. Esto inyectó una carga constante de 100 req/s durante 40 segundos.

**Protocolo de 3 Corridas y Descarte:**
Se ejecutaron tres iteraciones independientes bajo idénticas condiciones. En cumplimiento del rigor estadístico, se descarta explícitamente la primera corrida para anular el sesgo del calentamiento (warm-up) de la Máquina Virtual de Java. La estadística final se calcula sobre las corridas válidas.

* **Corrida 1 (Descartada - Warm-up):** 4000 iteraciones a ~100 req/s. p95 = 3.82 ms.
* **Corrida 2 (Válida):** 4000 iteraciones a ~100 req/s. p95 = 2.78 ms.
* **Corrida 3 (Válida):** 4001 iteraciones a ~100 req/s. p95 = 2.73 ms.

**Estadística Final de las Corridas Válidas:**
* **Mediana del p95:** 2.755 ms (promedio de 2.78 y 2.73).
* **Códigos HTTP verificados:** 100% de éxito (HTTP 200) y 0 fallos.

## 4. Contraste con la Hipótesis de S3
* **Hipótesis (Semana 3):** p95 < 800 ms bajo una carga de 100 req/s.
* **Evidencia Medida (Semana 4):** La estadística obtenida arroja una mediana del p95 de 2.755 ms.
* **Conclusión:** Bajo las condiciones exactas medidas en este experimento (100 req/s en el entorno local documentado), el sistema logra procesar la carga manteniendo una latencia que cumple satisfactoriamente con el umbral estipulado en la hipótesis.
