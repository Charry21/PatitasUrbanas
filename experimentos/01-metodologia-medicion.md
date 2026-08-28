# Metodología y Resultados de Línea Base (Semana 4)

## 1. Trazabilidad de la Medición
* **Fecha de Ejecución:** 28 de agosto de 2026
* **Versión del Código (Commit Hash):** 4d13ad35b2b0eaa8a2938d05b28857d8c75ff697
* **Condiciones del Entorno:** Windows, Docker Desktop (WSL2), PostgreSQL 16, Java 21 + Spring Boot 3.3.4, k6.

## 2. Fase Exploratoria Inicial (Medición de Trazabilidad)
Como parte del ciclo de pruebas, se ejecutó una corrida inicial de 50 segundos utilizando 20 Usuarios Virtuales (VUs) con un `sleep(1)`.
* **Resultado de Carga:** Se alcanzó un throughput de ~16.17 req/s, generando 809 iteraciones.
* **Latencia:** p95 = 4.33 ms.
* **Conclusión de Fase:** Bajo estas condiciones específicas (16 req/s), el sistema base respondió sin errores. Sin embargo, esta carga no representa el volumen de 100 req/s exigido en la hipótesis de la Semana 3. La evidencia se conserva en el archivo `resultado-linea-base.txt` para mantener la trazabilidad experimental del proyecto.

## 3. Medición de Línea Base Formal (Contraste de Hipótesis S3)
Para alinear el experimento con el escenario de la Semana 3 (100 peticiones/s), se modificó el script de k6 utilizando el ejecutor `constant-arrival-rate`. Esto forzó una inyección exacta de 100 req/s durante 40 segundos.

**Protocolo de 3 Corridas:**
Se ejecutaron tres iteraciones idénticas de forma consecutiva. Aplicando la regla metodológica, la primera corrida se descarta por representar el periodo de calentamiento (warm-up) de la Máquina Virtual de Java (JVM) y la caché inicial de la base de datos.

* **Corrida 1 (Descartada - Warm-up):** 4000 peticiones a 99.99 req/s. p95 = 3.82 ms.
* **Corrida 2 (Válida):** 4000 peticiones a 99.99 req/s. p95 = 2.78 ms.
* **Corrida 3 (Válida):** 4001 peticiones a 100.01 req/s. p95 = 2.73 ms.

**Cálculo Estadístico:**
* **Mediana del p95 (Corridas 2 y 3):** 2.755 ms.
* **Códigos de Respuesta:** 100% de las peticiones en las corridas válidas retornaron HTTP 200.

## 4. Veredicto Arquitectónico
* **Hipótesis (Semana 3):** El p95 debe ser < 800 ms bajo una carga sostenida de 100 req/s.
* **Evidencia Experimental:** La mediana del p95 medida es de 2.755 ms bajo la carga exacta de 100 req/s.
* **Conclusión:** Los datos obtenidos de las corridas válidas demuestran que, bajo las condiciones evaluadas, el sistema base actual procesa la carga impuesta manteniendo la latencia dentro del umbral de tolerancia definido.

## 5. Variables de Invalidación
La medición perdería validez si ocurren alteraciones tales como: la ejecución concurrente de procesos de alto consumo de CPU/E/S en el anfitrión, limitaciones dinámicas de hipervisor aplicadas por WSL2, o el estrangulamiento térmico (thermal throttling) del procesador del equipo.
