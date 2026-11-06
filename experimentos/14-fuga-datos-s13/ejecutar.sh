#!/usr/bin/env bash
# Prueba de fuga de datos S13 (preregistro: README.md). Ejecutar desde la raíz del repositorio.
# Uso: bash experimentos/14-fuga-datos-s13/ejecutar.sh <antes|despues>
# Variables opcionales:
#   URL_API     URL con la que se habla con la API (por defecto http://localhost:3000)
#   PUERTO_CLARO puerto HTTP que se prueba por la interfaz externa en P11 (por defecto 3000)
#   TOKENS      carpeta creada por generar_tokens.py (por defecto /tmp/tokens)
set -uo pipefail
ETIQUETA="${1:?uso: ejecutar.sh <antes|despues>}"
EJECUCIONES=3
DIR=experimentos/14-fuga-datos-s13
URL_API="${URL_API:-http://localhost:3000}"
PUERTO_CLARO="${PUERTO_CLARO:-3000}"
TOKENS="${TOKENS:-/tmp/tokens}"
API=patitas_urbanas_api
BD=patitas_urbanas_db
MARCADOR=MARCADOR_FUGA_S13
CLAVE_REPO=adminpassword
RED_EXTERNA=s13-red-externa
BUSCAR='/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5'

# Predicciones fijadas en README.md §3, antes de ejecutar.
declare -A PRED_antes=( [P01]=SIN_FUGA [P02]=SIN_FUGA [P03]=FUGA [P04]=FUGA [P05]=SIN_FUGA [P06]=FUGA [P07]=FUGA
  [P08]=FUGA [P09]=SIN_FUGA [P10]=SIN_FUGA [P11]=FUGA [P12]=HALLAZGO [P13]=FUGA )
declare -A PRED_despues=( [P01]=SIN_FUGA [P02]=SIN_FUGA [P03]=SIN_FUGA [P04]=SIN_FUGA [P05]=SIN_FUGA [P06]=SIN_FUGA
  [P07]=SIN_FUGA [P08]=FUGA_PARCIAL [P09]=SIN_FUGA [P10]=SIN_FUGA [P11]=SIN_FUGA [P12]=SIN_FUGA [P13]=SIN_FUGA )

ts() { date -u +%FT%T.%3NZ; }
token() { cat "$TOKENS/$1.jwt" 2>/dev/null; }
autorizacion=()
[ "$ETIQUETA" = despues ] && autorizacion=(-H "Authorization: Bearer $(token valido)")

http() { # archivo_salida, argumentos de curl...; imprime el código HTTP
  local salida="$1"; shift
  curl -sk -m 20 -o "$salida" -w '%{http_code}' "$@"
}
filas() {
  docker exec "$BD" sh -c "psql -U \"\$POSTGRES_USER\" -d \"\$POSTGRES_DB\" -tAc \"select (select count(*) from solicitud_adopcion) || ',' || (select count(*) from etapa_adopcion)\"" 2>&1
}

{ echo "Fecha: $(ts)"; echo "Etiqueta: $ETIQUETA"; echo "Commit de esta rama: $(git rev-parse HEAD)"
  echo "Rama: $(git rev-parse --abbrev-ref HEAD)"; echo "Código de la API (imagen): $(docker inspect -f '{{.Config.Image}} {{.Image}}' $API)"
  . /etc/os-release; echo "SO: $PRETTY_NAME"; echo "CPUs: $(nproc)"; docker version --format 'Docker {{.Server.Version}}'
  docker exec "$BD" sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "select version()"'
  echo "URL_API: $URL_API"; echo "Puertos publicados:"; docker ps --format '{{.Names}} {{.Ports}}'
} > /tmp/entorno.$$

sondas() {
  local R="$1"; local E="$R/evidencia"; mkdir -p "$E"
  local T="$R/sondas.tsv"; export T; printf 'sonda\tclasificacion\tdetalle\n' > "$T"
  anotar() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$T"; }

  # Marcador
  local c; c=$(http "$E/00-marcador.txt" -X POST "${autorizacion[@]}" "$URL_API/api/adopciones?estado=$MARCADOR&nombreEtapa=$MARCADOR")
  echo "marcador -> HTTP $c" >> "$E/00-marcador.txt"

  # P01
  local fuga=0 det=""
  for r in /api/adopciones /api/adopciones/1 /api/solicitudes; do
    c=$(http "$E/P01.tmp" "$URL_API$r"); { echo "GET $r -> $c"; cat "$E/P01.tmp"; echo; } >> "$E/P01.txt"
    grep -q "$MARCADOR" "$E/P01.tmp" && fuga=1; det="$det$r=$c "
  done; rm -f "$E/P01.tmp"
  anotar P01 "$([ $fuga = 1 ] && echo FUGA || echo SIN_FUGA)" "$det"

  # P02
  fuga=0; det=""
  c=$(http "$E/P02.tmp" "$URL_API/actuator"); { echo "GET /actuator -> $c"; cat "$E/P02.tmp"; echo; } >> "$E/P02.txt"; det="actuator=$c "
  for r in env configprops heapdump threaddump beans mappings metrics loggers prometheus; do
    c=$(http "$E/P02.tmp" "$URL_API/actuator/$r"); echo "GET /actuator/$r -> $c" >> "$E/P02.txt"
    [ "$c" = 200 ] && fuga=1; det="$det$r=$c "
  done; rm -f "$E/P02.tmp"
  anotar P02 "$([ $fuga = 1 ] && echo FUGA || echo SIN_FUGA)" "$det"

  # P03
  c=$(http "$E/P03.txt" "$URL_API/actuator/health")
  if grep -Eq 'components|database|diskSpace|"path"' "$E/P03.txt"; then anotar P03 FUGA "HTTP $c: $(head -c 160 "$E/P03.txt")"; else anotar P03 SIN_FUGA "HTTP $c: $(head -c 160 "$E/P03.txt")"; fi

  # P04
  local largo; largo=$(printf 'x%.0s' $(seq 1 300)); fuga=0; det=""
  for caso in tipo largo test_fallo ruta; do
    case $caso in
      tipo) c=$(http "$E/P04-$caso.txt" "$URL_API/api/mascotas/buscar?lat=abc&lng=0&radio=0");;
      largo) c=$(http "$E/P04-$caso.txt" -X POST "${autorizacion[@]}" "$URL_API/api/adopciones?estado=$largo");;
      test_fallo) c=$(http "$E/P04-$caso.txt" -X POST "${autorizacion[@]}" "$URL_API/api/adopciones/test-fallo");;
      ruta) c=$(http "$E/P04-$caso.txt" "$URL_API/no-existe-s13");;
    esac
    det="$det$caso=$c "
    grep -Eqi '"trace"|java\.|org\.|insert into|select |Fallo simulado|could not|constraint' "$E/P04-$caso.txt" && { fuga=1; det="$det(interno) "; }
  done
  anotar P04 "$([ $fuga = 1 ] && echo FUGA || echo SIN_FUGA)" "$det"

  # P05
  local antes despues aceptadas=0; antes=$(filas); fuga=0; : > "$E/P05.txt"
  while IFS= read -r carga; do
    for param in estado nombreEtapa; do
      c=$(http "$E/P05.tmp" -X POST -G "${autorizacion[@]}" --data-urlencode "$param=$carga" "$URL_API/api/adopciones")
      { echo "$param=$carga -> $c"; cat "$E/P05.tmp"; echo; } >> "$E/P05.txt"
      [ "$c" = 201 ] && aceptadas=$((aceptadas+1))
      grep -q "$MARCADOR" "$E/P05.tmp" && fuga=1
      grep -qi 'postgresql 1' "$E/P05.tmp" && fuga=1
    done
  done <<'CARGAS'
' OR '1'='1
'; DROP TABLE etapa_adopcion; --
x' UNION SELECT version(), null --
CARGAS
  rm -f "$E/P05.tmp"; despues=$(filas)
  local a1=${antes%,*} a2=${antes#*,} d1=${despues%,*} d2=${despues#*,}
  echo "filas antes=$antes después=$despues aceptadas=$aceptadas" >> "$E/P05.txt"
  { [ "$((d1-a1))" = "$aceptadas" ] && [ "$((d2-a2))" = "$aceptadas" ]; } 2>/dev/null || fuga=1
  anotar P05 "$([ $fuga = 1 ] && echo FUGA || echo SIN_FUGA)" "filas $antes -> $despues; aceptadas=$aceptadas"

  # P06
  local c1 c2; c1=$(http "$E/P06-1.txt" -X POST "$URL_API/api/adopciones"); c2=$(http "$E/P06-2.txt" -X POST "$URL_API/api/adopciones")
  if [[ $c1 == 2* || $c2 == 2* ]]; then anotar P06 FUGA "sin token: $c1 $c2; cuerpos: $(cat "$E/P06-1.txt") $(cat "$E/P06-2.txt")"; else anotar P06 SIN_FUGA "sin token: $c1 $c2"; fi

  # P07
  docker network create "$RED_EXTERNA" >/dev/null 2>&1
  local pasarela; pasarela=$(docker network inspect "$RED_EXTERNA" -f '{{(index .IPAM.Config 0).Gateway}}')
  local salida; salida=$(docker run --rm --network "$RED_EXTERNA" -e PGPASSWORD="$CLAVE_REPO" -e PGCONNECT_TIMEOUT=5 postgres:16 \
    psql -h "$pasarela" -p 5433 -U admin -d patitas_urbanas -tAc "select estado from solicitud_adopcion where estado='$MARCADOR' limit 1" 2>&1)
  { echo "Desde la red $RED_EXTERNA hacia $pasarela:5433 con la contraseña del repositorio"; echo "$salida"; } > "$E/P07.txt"
  if grep -q "$MARCADOR" <<<"$salida"; then anotar P07 FUGA "desde otra red leyó el marcador por $pasarela:5433"; else anotar P07 SIN_FUGA "$(head -c 140 <<<"$salida" | tr '\n' ' ')"; fi

  # P08
  local versionados jar entorno historial=no
  versionados=$(git grep -n -I -e "$CLAVE_REPO" -- docker-compose.yml app/src/main app/Dockerfile README.md .env.example 2>/dev/null)
  docker cp "$API:/app/app.jar" /tmp/fuga-app.$$.jar >/dev/null 2>&1
  jar=$(unzip -p /tmp/fuga-app.$$.jar BOOT-INF/classes/application.properties 2>/dev/null | grep -E '^spring.datasource.password=' )
  rm -f /tmp/fuga-app.$$.jar
  entorno=$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$API" | grep -E 'PASSWORD=' | sed -E 's/=.*/=<presente>/')
  [ -n "$(git log --all -S"$CLAVE_REPO" --oneline -- docker-compose.yml 2>/dev/null)" ] && historial=si
  { echo "--- archivos versionados"; echo "$versionados"; echo "--- jar"; echo "$jar"; echo "--- variables del contenedor (valor oculto)"; echo "$entorno"; echo "--- en el historial de Git: $historial"; } > "$E/P08.txt"
  local clave_en_jar=no; [[ $jar == *"$CLAVE_REPO"* ]] && clave_en_jar=si
  if [ -n "$versionados" ] || [ "$clave_en_jar" = si ]; then anotar P08 FUGA "versionados=$(grep -c . <<<"$versionados") jar=$clave_en_jar entorno=$(grep -c . <<<"$entorno") historial=$historial"
  elif [ -n "$entorno" ] || [ "$historial" = si ]; then anotar P08 FUGA_PARCIAL "versionados=0 jar=no entorno=$(grep -c . <<<"$entorno") historial=$historial"
  else anotar P08 SIN_FUGA "sin coincidencias"; fi

  # P09
  local en_log tokens_log; docker logs "$API" > "$E/P09-log-completo.tmp" 2>&1
  en_log=$(grep -c "$MARCADOR" "$E/P09-log-completo.tmp"); tokens_log=$(grep -c 'eyJ' "$E/P09-log-completo.tmp"); rm -f "$E/P09-log-completo.tmp"
  echo "líneas con el marcador: $en_log; líneas con un token: $tokens_log" > "$E/P09.txt"
  anotar P09 "$([ "$en_log" -gt 0 ] || [ "$tokens_log" -gt 0 ] && echo FUGA || echo SIN_FUGA)" "marcador=$en_log token=$tokens_log"

  # P10
  local ct co; ct=$(http "$E/P10-trace.txt" -X TRACE "$URL_API$BUSCAR")
  curl -sk -m 20 -D "$E/P10-cors.txt" -o /dev/null -H 'Origin: https://sitio-ajeno.example' "$URL_API$BUSCAR"
  co=$(curl -sk -m 20 -D - -o /dev/null -X OPTIONS -H 'Origin: https://sitio-ajeno.example' -H 'Access-Control-Request-Method: POST' "$URL_API/api/adopciones" | tee "$E/P10-preflight.txt" | grep -ci '^access-control-allow-origin')
  fuga=0; grep -qi '^TRACE ' "$E/P10-trace.txt" && fuga=1; grep -qi '^access-control-allow-origin' "$E/P10-cors.txt" && fuga=1; [ "$co" -gt 0 ] && fuga=1
  anotar P10 "$([ $fuga = 1 ] && echo FUGA || echo SIN_FUGA)" "TRACE=$ct preflight_aco=$co cabeceras: $(grep -iE '^(server|x-powered-by):' "$E/P10-cors.txt" | tr -d '\r' | tr '\n' ' ')"

  # P11
  local ip; ip=$(hostname -I | awk '{print $1}')
  c=$(http "$E/P11.txt" "http://$ip:$PUERTO_CLARO$BUSCAR")
  echo "http://$ip:$PUERTO_CLARO -> $c" >> "$E/P11.txt"
  if [ "$c" = 200 ]; then anotar P11 FUGA "HTTP en claro por $ip:$PUERTO_CLARO -> 200"; else anotar P11 SIN_FUGA "HTTP en claro por $ip:$PUERTO_CLARO -> $c"; fi

  # P12
  local uid; uid=$(docker exec "$API" id -u 2>&1); echo "id -u = $uid" > "$E/P12.txt"
  if [ "$uid" = 0 ]; then anotar P12 HALLAZGO "el proceso corre como root"; else anotar P12 SIN_FUGA "uid=$uid"; fi

  # P13
  fuga=0; det=""; : > "$E/P13.txt"
  c=$(http "$E/P13.tmp" -X POST "$URL_API/api/adopciones"); echo "sin_token -> $c" >> "$E/P13.txt"; [[ $c == 2* ]] && fuga=1; det="sin_token=$c "
  for caso in firma_incorrecta caducado alg_none confusion_hs256 emisor_incorrecto audiencia_incorrecta sin_permiso; do
    c=$(http "$E/P13.tmp" -X POST -H "Authorization: Bearer $(token "$caso")" "$URL_API/api/adopciones")
    echo "$caso -> $c $(head -c 120 "$E/P13.tmp")" >> "$E/P13.txt"; [[ $c == 2* ]] && fuga=1; det="$det$caso=$c "
  done
  c=$(http "$E/P13.tmp" -X POST -H "Authorization: Bearer $(token valido)" "$URL_API/api/adopciones"); echo "valido -> $c" >> "$E/P13.txt"; det="${det}valido=$c"; rm -f "$E/P13.tmp"
  anotar P13 "$([ $fuga = 1 ] && echo FUGA || echo SIN_FUGA)" "$det"

  docker network rm "$RED_EXTERNA" >/dev/null 2>&1
}

BASE="$DIR/resultados/$ETIQUETA"; mkdir -p "$BASE"; mv /tmp/entorno.$$ "$BASE/entorno.txt"
for n in $(seq 1 "$EJECUCIONES"); do
  sondas "$BASE/ejecucion-$n"
  sleep 2
done

# Comparación con las predicciones
declare -n PRED="PRED_$ETIQUETA"
{ printf 'sonda\tpredicho\tejecucion-1\tejecucion-2\tejecucion-3\tveredicto\n'
  for p in P01 P02 P03 P04 P05 P06 P07 P08 P09 P10 P11 P12 P13; do
    fila="$p\t${PRED[$p]}"; ok=NO_REFUTADA
    for n in 1 2 3; do
      o=$(awk -F'\t' -v s="$p" '$1==s{print $2}' "$BASE/ejecucion-$n/sondas.tsv"); fila="$fila\t$o"
      [ "$o" = "${PRED[$p]}" ] || ok=REFUTADA
    done
    printf "$fila\t$ok\n"
  done
} | tee "$BASE/comparacion.tsv"
