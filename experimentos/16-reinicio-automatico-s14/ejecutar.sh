#!/usr/bin/env bash
# Reinicio automático R-10 y conservación de datos R-11 (preregistro: README.md).
# Ejecutar desde la raíz del repositorio. Requiere la imagen patitas-urbanas-api:s13-sin (main) y la BD en marcha.
set -uo pipefail
R=experimentos/16-reinicio-automatico-s14/resultados
API=patitas_urbanas_api
RED="$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' patitas_urbanas_db)"
BUSCAR='http://localhost:3000/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5'
mkdir -p "$R"
ts() { date -u +%FT%T.%3NZ; }

lanzar() { # política de reinicio, ddl-auto
  docker rm -f "$API" >/dev/null 2>&1
  docker exec patitas_urbanas_db psql -q -U admin -d patitas_urbanas -c 'drop table if exists etapa_adopcion, solicitud_adopcion cascade' >/dev/null 2>&1
  docker run -d --name "$API" --network "$RED" -p 3000:3000 --restart "$1" \
    -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=adminpassword -e POSTGRES_DB=patitas_urbanas -e DB_HOST=postgres_db \
    -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres_db:5432/patitas_urbanas \
    -e SPRING_JPA_HIBERNATE_DDL_AUTO="$2" patitas-urbanas-api:s13-sin >/dev/null
  for _ in $(seq 1 90); do curl -fs http://localhost:3000/actuator/health | grep -q '"status":"UP"' && return 0; sleep 1; done
  echo "La API no arrancó"; return 1
}
filas() { docker exec patitas_urbanas_db psql -U admin -d patitas_urbanas -tAc "select (select count(*) from solicitud_adopcion) || ',' || (select count(*) from etapa_adopcion)" 2>&1; }
estado() { docker inspect -f 'estado={{.State.Status}} reinicios={{.RestartCount}}' "$API"; }

ciclo() { # fase, número
  local ok=0
  for _ in 1 2 3 4 5; do [ "$(curl -s -m 10 -o /dev/null -w '%{http_code}' -X POST http://localhost:3000/api/adopciones)" = 201 ] && ok=$((ok+1)); done
  local antes pid t0 t1 c seg; antes=$(filas); pid=$(docker inspect -f '{{.State.Pid}}' "$API")
  t0=$(date +%s.%N); kill -9 "$pid"; echo "$(ts) fase=$1 ciclo=$2 kill -9 pid=$pid filas_antes=$antes posts_201=$ok"
  while :; do
    c=$(curl -s -m 1 -o /dev/null -w '%{http_code}' "$BUSCAR"); t1=$(date +%s.%N); seg=$(echo "$t1 - $t0" | bc)
    if [ "$c" = 200 ]; then echo "$(ts) fase=$1 ciclo=$2 primer_200_s=$seg"; break; fi
    if (( $(echo "$seg > 180" | bc) )); then echo "$(ts) fase=$1 ciclo=$2 SIN_200_EN_180_S"; break; fi
    sleep 0.2
  done
  for _ in $(seq 1 30); do curl -fs http://localhost:3000/actuator/health | grep -q '"status":"UP"' && break; sleep 1; done
  echo "$(ts) fase=$1 ciclo=$2 filas_despues=$(filas) $(estado)"
}

{ echo "Fecha UTC: $(ts)"; echo "Commit: $(git rev-parse HEAD)"; echo "Imagen: $(docker inspect -f '{{.Id}}' patitas-urbanas-api:s13-sin) (código de main 3f4b124)"
  . /etc/os-release; echo "SO: $PRETTY_NAME"; echo "CPU: $(nproc) vCPU; RAM: $(free -h | awk '/Mem:/{print $2}')"; docker version --format 'Docker {{.Server.Version}}'; } > "$R/entorno.txt"

{
  echo "== Fase 1, control HR5: sin restart"
  lanzar no create-drop
  pid=$(docker inspect -f '{{.State.Pid}}' "$API"); kill -9 "$pid"; echo "$(ts) kill -9 pid=$pid"; sleep 30; echo "$(ts) a los 30 s: $(estado)"

  echo "== Fase 2, R-10 sola (create-drop): HR1, HR2"
  lanzar unless-stopped create-drop
  for i in 1 2 3 4 5; do ciclo r10 "$i"; done
  echo "== Fase 2b, HR4: docker stop"
  docker stop "$API" >/dev/null; echo "$(ts) docker stop"; sleep 30; echo "$(ts) a los 30 s: $(estado)"

  echo "== Fase 3, R-10 + R-11 (update): HR1, HR3"
  lanzar unless-stopped update
  for i in 1 2 3 4 5; do ciclo r10r11 "$i"; done
  docker rm -f "$API" >/dev/null
} 2>&1 | tee "$R/bitacora.txt"
