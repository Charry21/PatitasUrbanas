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

## 2. Configuración de Semilla (Sesgo 80/20 y Zona Caliente)
Para garantizar un escenario de estrés realista según los lineamientos del curso, la base de datos fue inicializada con 5,000 registros de prueba aplicando una distribución 80/20:
* **Zona Caliente (Hotspot):** El 80% de los registros (4,000 mascotas) están concentrados espacialmente en el 20% del área de la ciudad (centro geográfico de Bogotá, coordenadas `lat=4.6097, lng=-74.0817`).
* **Dispersión:** El 20% restante (1,000 mascotas) está disperso de forma aleatoria en la periferia.
* **Operación:** El script de k6 apunta intencionalmente a esta zona caliente para forzar al índice espacial (GIST) a resolver la máxima densidad de datos bajo alta concurrencia.

## 3. Coherencia Escenario - Script
* **Escenario Definido (Semana 3):** Rendimiento en consultas de geolocalización de mascotas bajo una carga de 100 req/s.
* **Operación Medida (Semana 4):** El script inyecta tráfico contra el endpoint geoespacial (`/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5`). Se utiliza `constant-arrival-rate` para garantizar un volumen sostenido de 100 peticiones por segundo durante 40 segundos.

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
* **Evidencia Medida (Semana 4):** La mediana p95 obtenida es de 1.81 ms.
* **Conclusión:** El sistema procesa la carga sobre la zona caliente cumpliendo el umbral de rendimiento estipulado.
