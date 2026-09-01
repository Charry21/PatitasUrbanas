# Metodología y Resultados de Línea Base (Semana 4)

## 1. Trazabilidad de la Medición
* **Fecha de Ejecución:** 31 de agosto de 2026
* **Versión del Código (Commit Hash):** 8c7b9f58cace81b9a50f157b3fdb85df9c2c27e1
* **Condiciones del Entorno y Hardware:** 
  * Sistema Operativo: Windows, Docker Desktop (WSL2).
  * Motor de Base de Datos: PostgreSQL 16 con extensión PostGIS e índices espaciales (GIST).
  * Microservicio: Java 21 + Spring Boot 3.3.4.
  * Herramienta de Carga: k6.
  * Fuente de Energía: Equipo conectado a corriente alterna (AC) sin perfiles de ahorro de batería.
* **Configuración y Semilla de Datos:**
  * Volumen de la Semilla: 5,000 registros insertados en la base de datos local.
  * Distribución de la Semilla: Coordenadas distribuidas aleatoriamente dentro del área de Bogotá.

## 2. Coherencia Escenario - Script
* **Escenario Definido (Semana 3):** Rendimiento en consultas de geolocalización de mascotas bajo una carga de 100 req/s.
* **Operación Medida (Semana 4):** El script de k6 inyecta tráfico directamente contra el endpoint geoespacial (`/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5`). Se utiliza el modelo `constant-arrival-rate` para garantizar un volumen sostenido de 100 peticiones por segundo durante 40 segundos.

## 3. Protocolo de 3 Corridas y Tratamiento Estadístico
Se ejecutaron tres iteraciones independientes bajo idénticas condiciones. Para anular el sesgo de calentamiento (warm-up) de la Máquina Virtual de Java y la inicialización de conexiones, se descarta formalmente la primera corrida. La métrica final se calcula como la mediana de las corridas 2 y 3.

* **Corrida 1 (Descartada - Warm-up):** 4000 iteraciones, 100% éxito. p95 = 2.85 ms.
* **Corrida 2 (Válida):** 4000 iteraciones, 100% éxito. p95 = 1.82 ms.
* **Corrida 3 (Válida):** 4001 iteraciones, 100% éxito. p95 = 1.80 ms.

**Estadística Final Reportada:**
* **Mediana del p95 (Corridas Válidas):** 1.81 ms.
* **Códigos HTTP verificados:** 100% de respuestas HTTP 200 (0 fallos).

## 4. Contraste con la Hipótesis de S3
* **Hipótesis Estipulada (Semana 3):** El p95 debe ser inferior a 800 ms bajo una carga de 100 req/s para la búsqueda espacial.
* **Evidencia Medida (Semana 4):** La mediana del p95 consolidada es de 1.81 ms.
* **Conclusión:** Bajo el escenario evaluado contra el controlador base, la arquitectura resuelve la carga impuesta con una latencia que cumple de manera holgada el umbral crítico exigido en el diseño.
