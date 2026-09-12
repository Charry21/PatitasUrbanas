# Línea Base Congelada - Semana 6

Este documento congela el estado exacto del sistema desde el cual arranca el trabajo de Semana 6 (localización del fenómeno en la arquitectura), para poder distinguir evidencia obtenida sobre esta versión de evidencia obtenida sobre versiones posteriores si el código cambia durante la semana.

## Estado del repositorio
- Rama: main
- Commit: fde35cfee5522303746db8a1f57e7df20ee00d45
- Fecha de congelamiento: 12 de septiembre de 2026

## Versiones del entorno
- Aplicación: patitas-urbanas-api 0.0.1-SNAPSHOT, Java 21, Spring Boot 3.3.4
- Base de datos: PostgreSQL 16.15 (Debian 16.15-1.pgdg13+2)
- Herramienta de carga: k6 v2.2.0 (commit/00a9a1b7f5, go1.26.5, windows/amd64)

## Configuración activa
- docker-compose.yml: servicios postgres_db (con pg_stat_statements habilitado) y api_app (con SPRING_DATASOURCE_URL apuntando a postgres_db:5432)
- Hibernate statistics: habilitado (spring.jpa.properties.hibernate.generate_statistics=true)

## Estado de la semilla de datos
No aplica. El proyecto no tiene scripts de seed; las tablas se crean vacías mediante Hibernate ddl-auto=create-drop en cada arranque de la aplicación.

## Herramientas de medición activas
- pg_stat_statements (verificado funcionando, ver dossier/evidencia-consultas.md)
- Hibernate statistics (verificado funcionando, ver logs de arranque de la aplicación)
- k6 para pruebas de carga HTTP (ver experimentos/01-metodologia-medicion.md)

## Nota de uso
Cualquier evidencia de Semana 6 debe indicar si corresponde a esta línea base (commit fde35cfee5522303746db8a1f57e7df20ee00d45) o a una versión posterior. No deben mezclarse como si fueran la misma corrida.
