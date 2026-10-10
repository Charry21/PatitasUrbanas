#!/usr/bin/env bash
# Y1: 3 corridas por estado, BD limpia antes de cada corrida (protocolo §5.1-§5.2)
set -u
export COMPOSE_PROJECT_NAME=patitasurbanas
EV=/home/user/PatitasUrbanas/experimentos/spike-s10/reproduccion-2026-10-09
for pair in "base:antes" "spike:despues"; do
  w=${pair%%:*}; d=${pair##*:}
  cd /home/user/PatitasUrbanas-$w
  echo "# COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME"
  for n in 1 2 3; do
    log=$EV/$d/y1-corrida-$n.log
    { echo "# $(date -u +%FT%TZ) commit=$(git rev-parse --short HEAD) dir=$PWD COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME"
      echo "# docker compose down -v && docker compose up -d postgres_db"; } > $log
    docker compose down -v >>$log 2>&1
    docker compose up -d postgres_db >>$log 2>&1 || { echo "# up falló" >> $log; exit 1; }
    t=0; until [ "$(docker inspect -f "{{.State.Health.Status}}" patitas_urbanas_db 2>/dev/null)" = healthy ]; do sleep 2; t=$((t+2)); [ $t -gt 180 ] && { echo "# BD no healthy" >> $log; exit 1; }; done
    echo "# healthy $(date -u +%FT%TZ); cd app && mvn -B clean test" >> $log
    (cd app && mvn -B clean test) >> $log 2>&1
    echo "# exit=$? fin=$(date -u +%FT%TZ)" >> $log
  done
done
docker exec patitas_urbanas_db psql -U admin -d patitas_urbanas -c "SELECT version();" > $EV/postgres-version.txt 2>&1
docker compose down -v >/dev/null 2>&1
echo DONE
