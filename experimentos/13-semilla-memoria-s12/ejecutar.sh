#!/usr/bin/env bash
# Experimento 13 (preregistro: README.md). Ejecutar desde la raíz del repositorio con
# PostgreSQL (patitas_urbanas_db) y la API (mvn spring-boot:run) en marcha.
set -uo pipefail
D=experimentos/13-semilla-memoria-s12; R=$D/resultados; mkdir -p "$R"
DB=patitas_urbanas_db; K6=grafana/k6:latest
PID=$(pgrep -f 'com.patitasurbanas.PatitasUrbanasApplication' | head -1)
psqlc(){ docker exec -i $DB psql -q -U admin -d patitas_urbanas "$@"; }
{ echo "Fecha: $(date -u +%FT%TZ)"; echo "Commit: $(git rev-parse HEAD)"; . /etc/os-release; echo "SO: $PRETTY_NAME"; echo "CPUs: $(nproc) · RAM: $(free -g | awk '/Mem/{print $2}') GiB"; java -version 2>&1 | grep -v JAVA_TOOL | head -1; docker run --rm $K6 version | head -1; docker exec $DB psql -U admin -d patitas_urbanas -tAc 'select version()'; echo "PID API: $PID"; } > "$R/entorno.txt"
echo "== reposo: 30 s sin carga" ; python3 $D/muestreo_jvm.py "$PID" "$R/reposo.csv" 30
for cond in vacia sembrada; do
  for c in 1 2 3 4; do
    if [ $cond = vacia ]; then psqlc -c "TRUNCATE etapa_adopcion, solicitud_adopcion RESTART IDENTITY;"; else psqlc < $D/semilla.sql; fi
    antes=$(psqlc -tAc "select count(*) from solicitud_adopcion")
    python3 $D/muestreo_jvm.py "$PID" "$R/$cond-c$c.jvm.csv" & M=$!
    ini=$(date -u +%FT%TZ)
    docker run --rm --network host -v "$PWD/experimentos/10-crecimiento-s11:/s" -v "$PWD/$R:/r" $K6 run --quiet \
      -e USUARIOS=200 -e OPERACION=adopcion -e SALIDA=/r/$cond-c$c.json /s/escenario-crecimiento.js > "$R/$cond-c$c.txt" 2> "$R/$cond-c$c.err"; rc=$?
    kill $M; wait $M 2>/dev/null
    despues=$(psqlc -tAc "select count(*) from solicitud_adopcion"); sin=$(psqlc -tAc "select count(*) from solicitud_adopcion s where not exists (select 1 from etapa_adopcion e where e.solicitud_adopcion_id=s.id)")
    echo "$cond c$c inicio=$ini fin=$(date -u +%FT%TZ) rc=$rc filas_antes=$antes filas_despues=$despues sin_etapa=$sin $(cat "$R/$cond-c$c.txt")" | tee -a "$R/bitacora.txt"
    sleep 10
  done
done
