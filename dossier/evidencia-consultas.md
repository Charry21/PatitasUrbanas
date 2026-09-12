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
| Segunda corrida | 4 consultas de negocio observadas (BEGIN, insert solicitud_adopcion, SELECT FOR KEY SHARE, insert etapa_adopcion) — no se observó COMMIT como fila separada en esta corrida. |
| Tercera corrida | idéntica a la segunda (BEGIN, insert solicitud_adopcion, SELECT FOR KEY SHARE, insert etapa_adopcion) — tampoco se observó COMMIT como fila separada. |
| Condiciones | contenedor postgres_db reiniciado con `docker compose down && docker compose up -d --build`, estadísticas limpiadas con pg_stat_statements_reset() inmediatamente antes de la petición, una sola petición HTTP ejecutada con Invoke-RestMethod desde PowerShell |
| Commit del código | a667edc68a0692adbef296dbc85553a6e64a6699 |
| Fecha | Fri Sep 11 22:46:31 2026 -0500 |

## Detalle de las 5 consultas observadas

1. BEGIN
2. insert into solicitud_adopcion (estado,fecha_creacion) values ($1,$2) returning id
3. SELECT $2 FROM ONLY "public"."solicitud_adopcion" x WHERE "id" OPERATOR(pg_catalog.=) $1 FOR KEY SHARE OF x  (verificación automática de llave foránea antes del insert en etapa_adopcion, no fue escrita explícitamente en el código)
4. insert into etapa_adopcion (fecha_cambio,nombre_etapa,solicitud_adopcion_id) values ($1,$2,$3) returning id
5. COMMIT

## Observación sobre variabilidad entre corridas

Las 3 corridas coinciden en las 3 operaciones de negocio reproducibles: dos INSERT (solicitud_adopcion, etapa_adopcion) y una verificación de llave foránea vía SELECT ... FOR KEY SHARE. Sin embargo, la primera corrida mostró un COMMIT como sentencia propia en pg_stat_statements, mientras que la segunda y tercera no. La explicación más probable, sin confirmar con certeza, es que el driver pgjdbc cambia de protocolo simple a protocolo extendido (sentencias preparadas del lado del servidor) después de las primeras ejecuciones de una consulta, lo cual altera cómo se registra el COMMIT en pg_stat_statements. Esto no afecta las operaciones de negocio reales, que se mantuvieron estables en las 3 corridas.
