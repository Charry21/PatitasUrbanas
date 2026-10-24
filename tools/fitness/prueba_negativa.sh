#!/usr/bin/env bash
# Prueba negativa de FF-01: cada caso inyecta una violación en una copia de app/ y
# exige que la fitness function FALLE (código 1). Si algún caso pasa, la prueba falla.
set -uo pipefail
FF="$(cd "$(dirname "$0")" && pwd)/fronteras_modulares.py"
RAIZ="${1:-app}"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
MC=src/main/java/com/patitasurbanas/api/mascotas/MascotaController.java
fallos=0
caso() { # nombre, comando sed que modifica la copia
  rm -rf "$T/app"; cp -r "$RAIZ" "$T/app"
  ( cd "$T/app" && eval "$2" )
  python3 -I "$FF" "$T/app" > "$T/salida.txt"; c=$?
  if [ $c -eq 1 ]; then echo "OK   $1 → FALLA como se espera"; else echo "MAL  $1 → código $c (debía ser 1)"; cat "$T/salida.txt"; fallos=$((fallos+1)); fi
}
caso "R1 import explícito de un repositorio de otro módulo" \
  "sed -i 's/^package com.patitasurbanas.api.mascotas;/&\nimport com.patitasurbanas.api.adopciones.SolicitudAdopcionRepository;/' $MC"
caso "R1 import con comodín de los modelos de otro módulo" \
  "sed -i 's/^package com.patitasurbanas.api.mascotas;/&\nimport com.patitasurbanas.api.adopciones.model.*;/' $MC"
caso "R1 nombre totalmente calificado en el código" \
  "sed -i 's/^public class MascotaController {/&\n    private com.patitasurbanas.api.adopciones.model.SolicitudAdopcion x;/' $MC"
caso "R2 shared depende de un módulo de negocio" \
  "mkdir -p src/main/java/com/patitasurbanas/api/shared && printf 'package com.patitasurbanas.api.shared;\nimport com.patitasurbanas.api.adopciones.AdopcionService;\npublic class Util {}\n' > src/main/java/com/patitasurbanas/api/shared/Util.java"
caso "R3 clase en un paquete de capa técnica" \
  "mkdir -p src/main/java/com/patitasurbanas/api/service && printf 'package com.patitasurbanas.api.service;\npublic class Suelta {}\n' > src/main/java/com/patitasurbanas/api/service/Suelta.java"
echo "Casos fallidos: $fallos"
exit $([ $fallos -eq 0 ] && echo 0 || echo 1)
