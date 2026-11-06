#!/usr/bin/env bash
# Costo de la capa de seguridad (preregistro: README.md). Ejecutar desde la raíz del repositorio.
# Requiere: BD en marcha (patitas_urbanas_db), imágenes patitas-urbanas-api:s13-sin y :s13-con,
#           caddy:2-alpine, k6, python3 + psutil y la carpeta de tokens de generar_tokens.py.
set -uo pipefail
DIR=experimentos/15-costo-seguridad-s13
RES="$DIR/resultados"
TOKENS="${TOKENS:-/tmp/tokens}"
CARPETA_TOKENS="$(cd "$TOKENS" && pwd)"
TOKEN="$(cat "$CARPETA_TOKENS/valido.jwt")"
RED="$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' patitas_urbanas_db)"
BLOQUES=(S C T T C S)
CORRIDAS=4
PAUSA=10
mkdir -p "$RES"

parar() { docker rm -f patitas_urbanas_api patitas_s13_proxy >/dev/null 2>&1 || true; }

arrancar() { # condición
  parar
  local imagen=patitas-urbanas-api:s13-sin
  local extra=()
  if [ "$1" != S ]; then
    imagen=patitas-urbanas-api:s13-con
    extra=(-v "$CARPETA_TOKENS/publica.pem:/run/secrets/jwt_publica.pem:ro"
           -e PATITAS_SEGURIDAD_JWT_CLAVE_PUBLICA=file:/run/secrets/jwt_publica.pem
           -e PATITAS_SEGURIDAD_JWT_EMISOR=https://identidad.patitasurbanas.example
           -e PATITAS_SEGURIDAD_JWT_AUDIENCIA=patitas-urbanas-api)
  fi
  docker run -d --name patitas_urbanas_api --network "$RED" -p 3000:3000 \
    -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=adminpassword -e POSTGRES_DB=patitas_urbanas -e DB_HOST=postgres_db \
    -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres_db:5432/patitas_urbanas \
    "${extra[@]}" "$imagen" >/dev/null
  for _ in $(seq 1 90); do
    curl -fs http://localhost:3000/actuator/health | grep -q '"status":"UP"' && break
    sleep 1
  done
  if [ "$1" = T ]; then
    docker run -d --name patitas_s13_proxy --network "$RED" -p 8443:8443 \
      -v "$PWD/$DIR/Caddyfile:/etc/caddy/Caddyfile:ro" caddy:2-alpine >/dev/null
    for _ in $(seq 1 30); do curl -sk -m 2 -o /dev/null -w '%{http_code}' "https://localhost:8443/actuator/health" | grep -q 200 && break; sleep 1; done
  fi
}

filas() {
  docker exec patitas_urbanas_db psql -U admin -d patitas_urbanas -tAc \
    "select (select count(*) from solicitud_adopcion) || ',' || (select count(*) from etapa_adopcion)" 2>/dev/null || echo n/d
}

{ echo "Fecha UTC: $(date -u +%FT%TZ)"; echo "Commit de esta rama: $(git rev-parse HEAD)"
  echo "Commit S: ${COMMIT_S:-n/d}"; echo "Commit C y T: ${COMMIT_C:-n/d}"
  . /etc/os-release; echo "SO: $PRETTY_NAME, kernel $(uname -r), $(uname -m)"
  echo "CPU: $(nproc) vCPU — $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2)"; echo "RAM: $(free -h | awk '/Mem:/{print $2}')"
  docker version --format 'Docker {{.Server.Version}}'; k6 version | head -1
  docker run --rm eclipse-temurin:21-jre java -version 2>&1 | head -1
  docker exec patitas_urbanas_db psql -U admin -d patitas_urbanas -tAc 'select version()'
  docker run --rm caddy:2-alpine caddy version
  for t in s13-sin s13-con; do echo "Imagen $t: $(docker inspect -f '{{.Id}}' patitas-urbanas-api:$t)"; done
  echo "Generador, API, BD y proxy en la misma máquina: sí"; } > "$RES/entorno.txt"

n=0
for COND in "${BLOQUES[@]}"; do
  n=$((n+1)); B="$RES/bloque-$n-$COND"; mkdir -p "$B"
  echo "$(date -u +%FT%TZ) bloque $n condición $COND: arranque" | tee -a "$RES/bitacora.txt"
  arrancar "$COND"
  URL=http://localhost:3000; [ "$COND" = T ] && URL=https://localhost:8443
  OPERACIONES=(buscar adopcion); [ "$COND" = C ] && OPERACIONES+=(sin_token)
  for OP in "${OPERACIONES[@]}"; do
    for C in $(seq 1 "$CORRIDAS"); do
      ID="$OP-c$C"
      python3 experimentos/10-crecimiento-s11/muestreo_cpu.py "$B/$ID.cpu.csv" &
      M=$!
      I=$(date -u +%FT%TZ)
      k6 run --quiet -e OPERACION="$OP" -e USUARIOS=200 -e DURACION=40s -e BASE_URL="$URL" -e TOKEN="$TOKEN" -e SALIDA="$B/$ID.json" \
        "$DIR/escenario-costo-seguridad.js" > "$B/$ID.txt" 2> "$B/$ID.stderr.txt"
      S=$?
      F=$(date -u +%FT%TZ)
      kill -TERM "$M"; wait "$M" 2>/dev/null
      echo "$I $F bloque=$n cond=$COND $ID exit=$S filas_bd=$(filas) :: $(head -1 "$B/$ID.txt")" | tee -a "$RES/bitacora.txt"
      sleep "$PAUSA"
    done
  done
  if [ "$COND" = C ]; then
    docker logs patitas_urbanas_api 2>&1 | grep -c 'AUDITORIA_ACCESO_DENEGADO' > "$B/lineas-auditoria.txt"
    docker logs patitas_urbanas_api 2>&1 | grep -m 5 'AUDITORIA_ACCESO_DENEGADO' > "$B/muestra-auditoria.txt"
  fi
  docker stats --no-stream patitas_urbanas_api patitas_urbanas_db > "$B/docker-stats.txt" 2>/dev/null
done
parar
echo "$(date -u +%FT%TZ) fin" | tee -a "$RES/bitacora.txt"
