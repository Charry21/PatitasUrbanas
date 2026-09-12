# Evidencia de consultas por petición

| Campo | Evidencia |
|---|---|
| Endpoint / operación | POST /api/adopciones |
| Método HTTP | POST |
| Parámetros | estado=PENDIENTE, nombreEtapa=SOLICITUD_RECIBIDA |
| Base de datos | PostgreSQL 16 |
| Estado de pg_stat_statements | verificado (extensión creada y funcionando, confirmado con SELECT * FROM pg_stat_statements) |
| Hibernate statistics | verificado (habilitado en application.properties, logs confirman "Statistics initialized [enabled=true]") |
| Peticiones ejecutadas | 1 |
| Consultas observadas | 5 (excluyendo el propio comando SELECT pg_stat_statements_reset(), que no es parte de la petición) |
| Primera corrida | 5 consultas (BEGIN, INSERT solicitud_adopcion, SELECT FOR KEY SHARE, INSERT etapa_adopcion, COMMIT) |
| Segunda corrida | [pendiente] |
| Tercera corrida | [pendiente] |
| Condiciones | contenedor postgres_db reiniciado con `docker compose down && docker compose up -d --build`, estadísticas limpiadas con pg_stat_statements_reset() inmediatamente antes de la petición, una sola petición HTTP ejecutada con Invoke-RestMethod desde PowerShell |
| Commit del código | a667edc68a0692adbef296dbc85553a6e64a6699 |
| Fecha | Fri Sep 11 22:46:31 2026 -0500 |

## Detalle de las 5 consultas observadas

1. BEGIN
2. insert into solicitud_adopcion (estado,fecha_creacion) values ($1,$2) returning id
3. SELECT $2 FROM ONLY "public"."solicitud_adopcion" x WHERE "id" OPERATOR(pg_catalog.=) $1 FOR KEY SHARE OF x  (verificación automática de llave foránea antes del insert en etapa_adopcion, no fue escrita explícitamente en el código)
4. insert into etapa_adopcion (fecha_cambio,nombre_etapa,solicitud_adopcion_id) values ($1,$2,$3) returning id
5. COMMIT
