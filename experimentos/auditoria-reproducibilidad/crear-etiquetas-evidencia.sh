#!/usr/bin/env bash
# Crea y publica las etiquetas evidencia/spike1-* sobre los commits ORIGINALES
# del spike 1 (decisión E4, experimentos/11-auditoria-reproducibilidad.md §6.1).
# Ejecutar desde la raíz de un clon de Charry21/PatitasUrbanas:
#   bash experimentos/auditoria-reproducibilidad/crear-etiquetas-evidencia.sh
# Comprueba antes de etiquetar que cada original tiene el mismo árbol que su copia en main.
set -euo pipefail
git fetch origin '+refs/heads/*:refs/remotes/origin/*'
while read -r nombre original copia; do
  git cat-file -e "$original^{commit}" || { echo "No se encuentra $original"; exit 1; }
  if [ "$(git rev-parse "$original^{tree}")" != "$(git rev-parse "$copia^{tree}")" ]; then
    echo "El árbol de $original no coincide con $copia"; exit 1
  fi
  git tag -a "evidencia/spike1-$nombre" "$original" \
    -m "Evidencia del spike 1: commit original $original (copia en main: $copia). Ver experimentos/07-trazabilidad-temporal.md §7."
done <<'LISTA'
00-base 887ccf1 6ad651d
01-preregistro 3d458a2 dd451cf
02-linea-base af02cce b52207e
03-control-y2 4883f9c 6508379
04-cambio 1e522df 44ede36
05-mediciones d97cbf3 ac85955
06-veredicto e9bcd93 7488569
07-integracion 7b1f022 4b6a0aa
LISTA
git push origin 'refs/tags/evidencia/spike1-*'
git ls-remote --tags origin 'evidencia/*'
