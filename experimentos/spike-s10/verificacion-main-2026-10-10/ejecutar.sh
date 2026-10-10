#!/usr/bin/env bash
# Y1 (3 corridas, BD limpia en cada una) e Y3 (medir_y3.sh) sobre el commit actual.
# Uso, desde la raíz del repositorio: experimentos/spike-s10/verificacion-main-2026-10-10/ejecutar.sh
set -u
export COMPOSE_PROJECT_NAME=patitasurbanas
EV=experimentos/spike-s10/verificacion-main-2026-10-10
for n in 1 2 3; do
  log=$EV/y1-corrida-$n.log
  { echo "# $(date -u +%FT%TZ) commit=$(git rev-parse --short HEAD) COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME"
    echo "# docker compose down -v && docker compose up -d postgres_db"; } > $log
  docker compose down -v >>$log 2>&1
  docker compose up -d postgres_db >>$log 2>&1 || { echo "# up falló" >> $log; exit 1; }
  t=0; until [ "$(docker inspect -f "{{.State.Health.Status}}" patitas_urbanas_db 2>/dev/null)" = healthy ]; do sleep 2; t=$((t+2)); [ $t -gt 180 ] && { echo "# BD no healthy" >> $log; exit 1; }; done
  echo "# healthy $(date -u +%FT%TZ); cd app && mvn -B clean test" >> $log
  (cd app && mvn -B clean test) >> $log 2>&1
  echo "# exit=$? fin=$(date -u +%FT%TZ)" >> $log
done
docker exec patitas_urbanas_db psql -U admin -d patitas_urbanas -c "SELECT version();" > $EV/postgres-version.txt 2>&1
echo "# Y3 inicio $(date -u +%FT%TZ)" > $EV/y3-ejecucion.log
experimentos/spike-s10/medir_y3.sh $EV/y3 >> $EV/y3-ejecucion.log 2>&1
echo "# Y3 exit=$? fin=$(date -u +%FT%TZ)" >> $EV/y3-ejecucion.log
docker compose down -v >/dev/null 2>&1
