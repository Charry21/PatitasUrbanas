#!/usr/bin/env bash
# Inyección de fallos S12 (preregistro: README.md). Ejecutar desde la raíz del repositorio.
set -uo pipefail
R=experimentos/12-inyeccion-fallos-s12/resultados; mkdir -p "$R"
U=http://localhost:3000; DB=patitas_urbanas_db
ts(){ date -u +%FT%T.%3NZ; }
req(){ # metodo ruta etiqueta
  local o; o=$(curl -s -m 70 -o /tmp/claude-0/cuerpo -w '%{http_code} %{time_total}' -X "$1" "$U$2"); echo "$(ts) $3 $1 $2 -> $o $(head -c 160 /tmp/claude-0/cuerpo | tr '\n' ' ')"; }
filas(){ docker exec $DB psql -U admin -d patitas_urbanas -tAc "select (select count(*) from solicitud_adopcion), (select count(*) from etapa_adopcion), (select count(*) from solicitud_adopcion s where not exists (select 1 from etapa_adopcion e where e.solicitud_adopcion_id=s.id))" 2>&1; }
{ echo "Fecha: $(ts)"; echo "Commit: $(git rev-parse HEAD)"; . /etc/os-release; echo "SO: $PRETTY_NAME"; java -version 2>&1 | grep -v JAVA_TOOL | head -1; mvn -v 2>&1 | grep -v JAVA_TOOL | head -1; docker version --format 'Docker {{.Server.Version}}'; docker exec $DB psql -U admin -d patitas_urbanas -tAc 'select version()'; echo "CPUs: $(nproc)"; } > "$R/entorno.txt"
ok=0
for c in 1 2 3; do
  B="$R/ciclo-$c.txt"; : > "$B"
  { echo "== ciclo $c: línea base"; for i in 1 2 3; do l=$(req POST /api/adopciones base); echo "$l"; [[ $l == *"-> 201 "* ]] && ok=$((ok+1)); done
    for i in 1 2 3; do req GET "/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5" base; done; req GET /actuator/health base
    echo "== ciclo $c: F1 docker stop $(ts)"; docker stop $DB >/dev/null
    for i in 1 2 3; do l=$(req POST /api/adopciones F1); echo "$l"; [[ $l == *"-> 201 "* ]] && ok=$((ok+1)); done
    for i in 1 2 3; do req GET "/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5" F1; done
    for i in 1 2 3; do req GET /actuator/health F1; done
    echo "== ciclo $c: F2 docker start $(ts)"; docker start $DB >/dev/null
    until [ "$(docker inspect -f '{{.State.Health.Status}}' $DB)" = healthy ]; do sleep 1; done; t0=$(date +%s.%N); echo "$(ts) BD healthy"
    while :; do l=$(req POST /api/adopciones F2); echo "$l"; if [[ $l == *"-> 201 "* ]]; then ok=$((ok+1)); echo "recuperado en $(echo "$(date +%s.%N) - $t0" | bc) s desde healthy"; break; fi
      (( $(echo "$(date +%s.%N) - $t0 > 60" | bc) )) && { echo "NO recuperado en 60 s"; break; }; sleep 2; done
    req GET /actuator/health F2
    echo "== ciclo $c: HF3 filas (solicitudes, etapas, sin_etapa): $(filas) · respuestas 201 acumuladas: $ok"
  } >> "$B" 2>&1
  cat "$B"
done
