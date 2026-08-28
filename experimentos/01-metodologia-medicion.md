# Metodología y Resultados de Línea Base (Semana 4)

## 1. Trazabilidad de la Medición
* **Fecha de Ejecución:** 28 de agosto de 2026
* **Versión del Código (Commit Hash):** 0f739f09feb4b5da2c328c11dfcdd53b595b11
* **Condiciones del Entorno y Hardware:** 
	* Sistema Operativo: Windows, Docker Desktop (WSL2)
	* Motor de Base de Datos: PostgreSQL 16 con extensión PostGIS e índices espaciales (GIST)
	* Microservicio: Java 21 + Spring Boot 3.3.4
	* Herramienta de Carga: k6
	* Fuente de Energía: Conectado a corriente alterna (AC) con perfil de alto rendimiento.
* **Configuración y Semilla de Datos:**
	* Volumen de la Semilla: 5,000 registros geolocalizados de prueba.
	* Distribución de la Semilla: Coordenadas aleatorias distribuidas en un radio de 15 km en Bogotá.

## 2. Coherencia Escenario - Script
* **Escenario Definido (Semana 3):** Rendimiento en consultas de geolocalización de mascotas bajo una carga de 100 req/s.
* **Operación Medida (Semana 4):** El script de k6 ejecuta peticiones HTTP GET concurrentes contra el endpoint real de búsqueda geoespacial (`/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5`) utilizando el ejecutor `constant-arrival-rate` a una tasa constante de 100 req/s durante 40 segundos.

## 3. Protocolo de 3 Corridas y Tratamiento Estadístico
Se ejecutaron tres iteraciones independientes bajo idénticas condiciones. Se descarta la primera corrida por efectos de calentamiento (warm-up) de la JVM, reportando la estadística final a partir de las corridas válidas 2 y 3.

* **Corrida 1 (Descartada - Warm-up):** 3985 iteraciones, 100% éxito. p95 = 5.58 ms.
* **Corrida 2 (Válida):** 4000 iteraciones, 100% éxito. p95 = 2.67 ms.
* **Corrida 3 (Válida):** 4000 iteraciones, 100% éxito. p95 = 2.61 ms.

**Estadística Final Reportada:**
* **Mediana del p95 (Corridas 2 y 3):** 2.64 ms.
* **Códigos HTTP verificados:** 100% de respuestas HTTP 200 (0 fallos).

## 4. Contraste con la Hipótesis de S3
* **Hipótesis Estipulada (Semana 3):** p95 < 800 ms bajo una carga de 100 req/s para búsqueda geoespacial.
* **Evidencia Medida (Semana 4):** La mediana del p95 obtenida es de 2.64 ms.
* **Conclusión:** Bajo el escenario real medido sobre la operación espacial con la semilla de datos configurada, el sistema cumple satisfactoriamente y de forma holgada con el umbral de rendimiento estipulado.
