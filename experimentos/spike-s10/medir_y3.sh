#!/usr/bin/env bash
# Medición Y3 del spike de fronteras modulares (Semana 10).
# Procedimiento: experimentos/04-spike-especificacion-s9.md §5 (Y3, solicitudes S1–S3).
# Uso (desde la raíz del repositorio): experimentos/spike-s10/medir_y3.sh <directorio_salida>
# Requisitos: docker compose, mvn, curl, jq.
set -euo pipefail

OUT="$1"
mkdir -p "$OUT"
URL="http://localhost:3000"

# 1. Base de datos limpia
docker compose down -v >/dev/null 2>&1
docker compose up -d postgres_db >/dev/null 2>&1
until [ "$(docker inspect -f '{{.State.Health.Status}}' patitas_urbanas_db)" = healthy ]; do sleep 2; done

# 2. Aplicación levantada con mvn spring-boot:run (puerto 3000)
(cd app && mvn -B -q spring-boot:run > "../$OUT/app.log" 2>&1) &
APP_PID=$!
trap 'pkill -f "spring-boot:run" >/dev/null 2>&1 || true; pkill -f "com.patitasurbanas.PatitasUrbanasApplication" >/dev/null 2>&1 || true' EXIT
until curl -s -o /dev/null "$URL/api/mascotas/buscar?lat=0&lng=0&radio=1"; do
  kill -0 "$APP_PID" 2>/dev/null || { echo "La aplicación no arrancó; ver $OUT/app.log"; exit 1; }
  sleep 2
done

# 3. Solicitudes S1–S3, 3 repeticiones cada una
solicitud() { # $1 nombre, $2 metodo, $3 ruta
  for n in 1 2 3; do
    curl -s -o "$OUT/$1-$n.body.json" -w '%{http_code}\n' -X "$2" "$URL$3" > "$OUT/$1-$n.status"
    # Normalización: quitar solo el identificador (idSolicitud); ordenar claves
    jq -S 'del(.idSolicitud)' "$OUT/$1-$n.body.json" > "$OUT/$1-$n.norm.json"
  done
}
solicitud S1 POST "/api/adopciones"
solicitud S2 POST "/api/adopciones?estado=PENDIENTE&nombreEtapa=SOLICITUD_RECIBIDA"
solicitud S3 GET  "/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5"

# 4. Resumen: código HTTP y estructura (claves y tipos) por solicitud
for s in S1 S2 S3; do
  for n in 1 2 3; do
    echo "$s-$n status=$(cat "$OUT/$s-$n.status") cuerpo_normalizado=$(jq -c . "$OUT/$s-$n.norm.json") tipos=$(jq -c 'with_entries(.value |= type)' "$OUT/$s-$n.body.json")"
  done
done | tee "$OUT/resumen.txt"
