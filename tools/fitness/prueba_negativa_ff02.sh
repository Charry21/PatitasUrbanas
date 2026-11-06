#!/usr/bin/env bash
# Prueba negativa de FF-02: cada caso rompe un control en una copia y exige que la fitness function FALLE.
set -uo pipefail
FF="$(cd "$(dirname "$0")" && pwd)/configuracion_segura.py"
RAIZ="$(cd "${1:-.}" && pwd)"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
P=app/src/main/resources/application.properties
# Sin este control, una base que ya falla haría pasar todos los casos.
python3 -I "$FF" "$RAIZ" > /dev/null || { echo "La configuración de partida no cumple FF-02: la prueba negativa no sería válida"; exit 1; }
fallos=0
caso() { # nombre, comando que modifica la copia
  rm -rf "$T/r"; mkdir -p "$T/r/app/src/main/resources" "$T/r/app/src/main/java/com/patitasurbanas/api/config"
  cp "$RAIZ/docker-compose.yml" "$RAIZ/docker-compose.produccion.yml" "$T/r/"
  cp "$RAIZ/app/Dockerfile" "$RAIZ/app/pom.xml" "$T/r/app/"; cp "$RAIZ/$P" "$T/r/$P"
  cp "$RAIZ/app/src/main/java/com/patitasurbanas/api/config/SeguridadConfig.java" "$T/r/app/src/main/java/com/patitasurbanas/api/config/"
  ( cd "$T/r" && eval "$2" )
  python3 -I "$FF" "$T/r" > "$T/salida.txt"; c=$?
  if [ $c -eq 1 ]; then echo "OK   $1 → FALLA como se espera"; else echo "MAL  $1 → código $c (debía ser 1)"; cat "$T/salida.txt"; fallos=$((fallos+1)); fi
}
caso "S1 Actuator expone env" "sed -i 's/^management.endpoints.web.exposure.include=.*/management.endpoints.web.exposure.include=health,env/' $P"
caso "S2 health muestra detalles" "sed -i 's/^management.endpoint.health.show-details=.*/management.endpoint.health.show-details=always/' $P"
caso "S3 contraseña literal en properties" "sed -i 's/^spring.datasource.password=.*/spring.datasource.password=secreto/' $P"
caso "S3 contraseña literal en Compose" "sed -i 's/POSTGRES_PASSWORD: .*/POSTGRES_PASSWORD: secreto/' docker-compose.yml"
caso "S4 BD publicada en todas las interfaces" "sed -i 's/127.0.0.1:5433:5432/5433:5432/' docker-compose.yml"
caso "O1 API sin reinicio automático" "sed -i '/restart: unless-stopped/d' docker-compose.yml"
caso "O2 reinicio automático con create-drop" "sed -i 's/SPRING_JPA_HIBERNATE_DDL_AUTO=update/SPRING_JPA_HIBERNATE_DDL_AUTO=create-drop/' docker-compose.yml"
caso "S5 API publicada en producción" "sed -i '0,/ports: !reset \[\]/{/ports: !reset \[\]/d}' docker-compose.produccion.yml"
caso "S7 imagen como root" "sed -i '/^USER /d' app/Dockerfile"
caso "S9 rutas no declaradas permitidas" "sed -i 's/.anyRequest().denyAll()/.anyRequest().permitAll()/' app/src/main/java/com/patitasurbanas/api/config/SeguridadConfig.java"
echo "Casos fallidos: $fallos"
exit $([ $fallos -eq 0 ] && echo 0 || echo 1)
