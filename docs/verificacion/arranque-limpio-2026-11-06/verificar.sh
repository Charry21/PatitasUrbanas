#!/usr/bin/env bash
# Verificación del paso 2 en una máquina limpia, siguiendo el README con app/Dockerfile.
# La ejecutó GitHub Actions porque el entorno de la IA no puede construir app/Dockerfile (F-08).
set -u
fallos=0
ok()  { echo "OK   $1"; }
mal() { echo "MAL  $1"; fallos=$((fallos+1)); }
igual() { if [ "$2" = "$3" ]; then ok "$1 -> $2"; else mal "$1 -> obtenido '$2', esperado '$3'"; fi; }
sql() { docker exec patitas_urbanas_db sh -c "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"$1\""; }
filas() { sql "select count(*) from solicitud_adopcion"; }
esperar() { for _ in $(seq 1 "${2:-120}"); do [ "$(curl -sk -m 3 -o /dev/null -w '%{http_code}' "$1")" = 200 ] && return 0; sleep 1; done; return 1; }
API=http://localhost:3000
BUSCAR='/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5'

echo "== Entorno"; date -u +%FT%TZ; git rev-parse HEAD; docker version --format 'Docker {{.Server.Version}}'; docker compose version; java -version 2>&1 | head -1

echo "== A. Arranque limpio según el README"
cp .env.example .env
CLAVE=$(openssl rand -hex 16); sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$CLAVE/" .env
python3 experimentos/14-fuga-datos-s13/generar_tokens.py secretos
TOKEN=$(cat secretos/valido.jwt)
inicio=$(date +%s)
if docker compose up -d --build 2>&1 | tail -6; then :; fi
esperar "$API/actuator/health" 120 && ok "API arriba, construida con app/Dockerfile, en $(( $(date +%s)-inicio )) s" || { mal "La API no arrancó"; docker compose logs --tail 40; exit 1; }

echo "== B. Comprobaciones del paso 2"
igual "health sin detalles" "$(curl -s $API/actuator/health)" '{"status":"UP"}'
igual "POST sin token" "$(curl -s -o /dev/null -w '%{http_code}' -X POST $API/api/adopciones)" 401
for i in 1 2 3; do igual "POST con token ($i)" "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "Authorization: Bearer $TOKEN" $API/api/adopciones)" 201; done
igual "búsqueda pública" "$(curl -s -o /dev/null -w '%{http_code}' "$API$BUSCAR")" 200
igual "búsqueda con tipo inválido" "$(curl -s -o /dev/null -w '%{http_code}' "$API/api/mascotas/buscar?lat=abc&lng=0&radio=0")" 400
igual "estado de 300 caracteres" "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "Authorization: Bearer $TOKEN" "$API/api/adopciones?estado=$(printf 'x%.0s' $(seq 1 300))")" 400
igual "filas antes de reiniciar" "$(filas)" 3
docker compose restart api_app 2>&1 | tail -1; esperar "$API/actuator/health" 90
igual "filas después de docker compose restart" "$(filas)" 3
pid=$(docker inspect -f '{{.State.Pid}}' patitas_urbanas_api); t0=$(date +%s.%N); sudo kill -9 "$pid"
esperar "$API$BUSCAR" 120 && echo "primer 200 tras kill -9: $(python3 -c "import time;print(round(time.time()-$t0,2))") s"
igual "filas después de kill -9" "$(filas)" 3
igual "reinicios automáticos" "$(docker inspect -f '{{.RestartCount}}' patitas_urbanas_api)" 1
igual "usuario del proceso" "$(docker exec patitas_urbanas_api id -u)" 10001
igual "API solo en loopback" "$(docker port patitas_urbanas_api 3000/tcp | sort -u | head -1)" "127.0.0.1:3000"
igual "BD solo en loopback" "$(docker port patitas_urbanas_db 5432/tcp | sort -u | head -1)" "127.0.0.1:5433"

echo "== C. Pruebas de la API contra la BD de Compose"
(cd app && POSTGRES_PASSWORD="$CLAVE" mvn -B -q test 2>&1 | tail -4; echo "mvn test: código ${PIPESTATUS[0]}"; grep -h 'Tests run' target/surefire-reports/*.txt | cut -c1-70)
igual "las tablas quedan borradas por create-drop de las pruebas" "$(sql "select count(*) from information_schema.tables where table_name='solicitud_adopcion'")" 0
docker compose restart api_app 2>&1 | tail -1; esperar "$API/actuator/health" 90
igual "tras reiniciar la API las tablas vuelven" "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "Authorization: Bearer $TOKEN" $API/api/adopciones)" 201

echo "== D. Volumen con la contraseña anterior"
docker compose down 2>&1 | tail -1
sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=otra-clave-distinta/" .env
docker compose up -d 2>&1 | tail -1; sleep 40
if docker compose logs api_app 2>&1 | grep -q 'password authentication failed'; then ok "con el volumen viejo la API no conecta: password authentication failed"; else mal "no apareció el error de contraseña"; docker compose logs --tail 15 api_app; fi
docker compose down -v 2>&1 | tail -1
docker compose up -d 2>&1 | tail -1
esperar "$API/actuator/health" 90 && ok "tras down -v arranca con la contraseña nueva" || mal "no arrancó tras down -v"
docker compose down -v 2>&1 | tail -1

echo "== E. Despliegue de producción y prueba de fuga con la imagen real"
F="-f docker-compose.yml -f docker-compose.produccion.yml"
sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$CLAVE/" .env
docker compose $F up -d --build 2>&1 | tail -1
esperar https://localhost/actuator/health 120 && ok "HTTPS por el proxy" || mal "el proxy no responde"
igual "HTTP redirige a HTTPS" "$(curl -s -o /dev/null -w '%{http_code}' http://localhost$BUSCAR)" 308
igual "POST con token por HTTPS" "$(curl -sk -o /dev/null -w '%{http_code}' -X POST -H "Authorization: Bearer $TOKEN" https://localhost/api/adopciones)" 201
igual "puerto 3000 cerrado" "$(curl -s -m 3 -o /dev/null -w '%{http_code}' $API$BUSCAR)" 000
igual "puerto 5433 cerrado" "$(curl -s -m 3 -o /dev/null -w '%{http_code}' localhost:5433)" 000
URL_API=https://localhost PUERTO_CLARO=3000 TOKENS=secretos bash experimentos/14-fuga-datos-s13/ejecutar.sh despues
if [ -f experimentos/14-fuga-datos-s13/resultados/despues/comparacion.tsv ]; then
  n=$(awk -F'\t' 'NR>1 && $6=="REFUTADA"' experimentos/14-fuga-datos-s13/resultados/despues/comparacion.tsv | wc -l); igual "predicciones refutadas en la prueba de fuga" "$n" 0
fi
docker compose $F down -v 2>&1 | tail -1

echo "== Resultado: $fallos comprobaciones fallidas"
exit $([ "$fallos" -eq 0 ] && echo 0 || echo 1)
