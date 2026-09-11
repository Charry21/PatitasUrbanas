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
