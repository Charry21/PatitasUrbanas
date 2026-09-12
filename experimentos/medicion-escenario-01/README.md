# Registro Explícito - Escenario 01 (Búsqueda de mascotas)

## Condiciones del entorno
SO Windows + Docker Desktop WSL2, PostgreSQL 16 sin PostGIS, Java 21 + Spring Boot 3.3.4, k6 v2.2.0, equipo conectado a AC.

## Commit
55933d1793eb8c4bd7eb64192f2045ab6a83f1a0

## Semilla de datos
No aplica. El endpoint GET /api/mascotas/buscar no consulta la base de datos (devuelve una respuesta JSON estática simulada, ver MascotaController.java), por lo que no existe un dataset sembrado que requiera una semilla aleatoria para esta medición.

## Tasa de acierto de los checks HTTP
100% (0 fallos en las 3 corridas válidas: 4001 + 4001 + 4000 = 12002 peticiones exitosas de 12002 totales)

## Corridas de referencia
Ver tabla completa en experimentos/01-metodologia-medicion.md, sección 6.
