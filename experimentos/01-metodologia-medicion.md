# Metodología y Resultados de Línea Base (Semana 4)

## 1. Trazabilidad de la Medición
* **Fecha de Ejecución:** 28 de agosto de 2026
* **Versión del Código (Commit Hash):** 4d13ad35b2b0eaa8a2938d05b28857d8c75ff697
* **Condiciones del Entorno:** Windows, Docker Desktop (WSL2), PostgreSQL 16, Java 21 + Spring Boot 3.3.4, k6.

## 2. Método de Inyección de Carga
Se ejecutó el script de k6 (`escenario-rendimiento.js`) configurado con un patrón de rampa de subida (10s a 20 VUs), carga sostenida (30s a 20 VUs) y rampa de bajada (10s a 0 VUs) apuntando al endpoint `/actuator/health`.

## 3. Protocolo de 3 Corridas y Tratamiento Estadístico
Siguiendo la disciplina experimental, se realizaron tres ejecuciones independientes bajo idénticas condiciones. Se descarta la primera corrida por efectos de calentamiento (warm-up) de la JVM y se calcula la mediana sobre las dos corridas válidas.

* **Corrida 1 (Descartada - Warm-up):** 809 iteraciones, 100% exitosas. Latencia p50 = 2.88 ms, p95 = 4.33 ms.
* **Corrida 2 (Incluida - Válida):** 4000 peticiones, 100% exitosas. Latencia p50 = 1.75 ms, p95 = 2.78 ms.
* **Corrida 3 (Incluida - Válida):** 4001 peticiones, 100% exitosas. Latencia p50 = 1.71 ms, p95 = 2.73 ms.

**Estadística Reportada (Mediana de las Corridas Válidas):**
* **Mediana del p50:** 1.73 ms.
* **Mediana del p95:** 2.755 ms.
* **Disponibilidad:** 100% de éxito en las peticiones HTTP 200 en todas las corridas.

## 4. Contraste con la Hipótesis de S3
* **Hipótesis Estipulada (Semana 3):** p95 < 800 ms.
* **Evidencia Medida (Semana 4):** La mediana del p95 obtenida es de 2.755 ms.
* **Conclusión:** Bajo las condiciones medidas de 20 VUs, el sistema cumple satisfactoriamente con el umbral de latencia estipulado en la hipótesis arquitectónica.
