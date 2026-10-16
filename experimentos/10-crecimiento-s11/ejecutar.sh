#!/usr/bin/env bash
# Ejecuta la serie de escalones de una operación.
# Uso: ./ejecutar.sh <buscar|adopcion> [carpeta_resultados]
# Requiere: API en http://localhost:3000 (contenedor patitas_urbanas_api), Postgres (patitas_urbanas_db), k6, python3 + psutil.
set -euo pipefail

OPERACION="${1:?operación: buscar | adopcion}"
DIR="$(cd "$(dirname "$0")" && pwd)"
RES="${2:-$DIR/resultados}/$OPERACION"
ESCALONES=(50 100 150 200)
CORRIDAS=4          # la corrida 1 de cada escalón se descarta (calentamiento); válidas: 2, 3 y 4
PAUSA=10            # segundos de reposo entre corridas
mkdir -p "$RES"

filas_bd() {
  docker exec patitas_urbanas_db psql -U admin -d patitas_urbanas -tAc \
    "select (select count(*) from solicitud_adopcion) || ',' || (select count(*) from etapa_adopcion)" 2>/dev/null || echo "n/d"
}

esperar_salud() {
  for _ in $(seq 1 60); do
    if curl -fs http://localhost:3000/actuator/health | grep -q '"status":"UP"'; then return 0; fi
    sleep 1
  done
  echo "La API no respondió UP en 60 s" >&2; return 1
}

# JVM nueva al inicio de cada serie, para que las dos operaciones partan del mismo estado.
echo "$(date -u +%FT%TZ) reinicio de la API" | tee -a "$RES/bitacora.txt"
docker restart patitas_urbanas_api >/dev/null
esperar_salud
echo "$(date -u +%FT%TZ) API UP; filas BD (solicitud,etapa) = $(filas_bd)" | tee -a "$RES/bitacora.txt"

for N in "${ESCALONES[@]}"; do
  for C in $(seq 1 "$CORRIDAS"); do
    ID="u${N}-c${C}"
    python3 "$DIR/muestreo_cpu.py" "$RES/$ID.cpu.csv" &
    PID_M=$!
    INICIO=$(date -u +%FT%TZ)
    set +e
    k6 run --quiet -e USUARIOS="$N" -e OPERACION="$OPERACION" -e SALIDA="$RES/$ID.json" \
      "$DIR/escenario-crecimiento.js" > "$RES/$ID.txt" 2> "$RES/$ID.stderr.txt"
    CODIGO=$?
    set -e
    FIN=$(date -u +%FT%TZ)
    kill -TERM "$PID_M"; wait "$PID_M" 2>/dev/null || true
    echo "$INICIO $FIN $ID exit=$CODIGO filas_bd=$(filas_bd) :: $(head -1 "$RES/$ID.txt")" | tee -a "$RES/bitacora.txt"
    sleep "$PAUSA"
  done
done
docker stats --no-stream patitas_urbanas_api patitas_urbanas_db > "$RES/docker-stats-final.txt" || true
