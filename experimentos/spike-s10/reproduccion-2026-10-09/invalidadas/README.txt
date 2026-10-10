Primer intento (2026-10-09 23:54-23:57 UTC). NO se usa como resultado.

Motivo: los worktrees ../PatitasUrbanas-base y ../PatitasUrbanas-spike tienen nombres de
directorio distintos, así que Docker Compose les asignó proyectos distintos
(patitasurbanas-base / patitasurbanas-spike). docker-compose.yml fija container_name:
patitas_urbanas_db, de modo que `docker compose down -v` desde el worktree del spike no
eliminó el contenedor creado desde el de la base y `docker compose up -d postgres_db`
falló con "Conflict. The container name ... is already in use" (ver cabecera de
despues/y1-corrida-*.log). Las 3 corridas de Y1 "después" se ejecutaron contra la BD
del proyecto base, no contra una BD limpia, lo que incumple §5.1 del protocolo.
medir_y3.sh, que usa `set -e`, abortó por el mismo conflicto en el estado después.

Corrección: repetir todas las mediciones Y1 e Y3 con COMPOSE_PROJECT_NAME=patitasurbanas
(el nombre que Compose usa en un clon llamado PatitasUrbanas), sin modificar
docker-compose.yml ni los scripts.

Se conservan estos registros sin editar como evidencia del fallo de procedimiento.
