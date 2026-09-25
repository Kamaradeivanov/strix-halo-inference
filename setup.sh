#!/usr/bin/env bash
# Déroule le setup d'inférence locale sur une machine Ubuntu fraîche.
#
#   ./setup.sh              toutes les étapes, dans l'ordre
#   ./setup.sh 20 90        seulement les étapes dont le nom commence par 20 et 90
#   ./setup.sh --list       liste les étapes
#
# Chaque étape est idempotente : on peut relancer le script sans risque.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/config.env"
source "$ROOT/lib.sh"

[[ $EUID -ne 0 ]] || die "lancer en utilisateur normal (sudo est appelé quand nécessaire)"

mapfile -t STEPS < <(find "$ROOT/steps" -maxdepth 1 -name '[0-9][0-9]-*.sh' | sort)

if [[ ${1:-} == --list ]]; then
  for s in "${STEPS[@]}"; do basename "$s"; done
  exit 0
fi

for s in "${STEPS[@]}"; do
  name="$(basename "$s")"
  if (($#)); then
    match=0
    for want in "$@"; do [[ $name == "$want"* ]] && match=1; done
    ((match)) || continue
  fi
  log "étape $name"
  ROOT="$ROOT" bash -euo pipefail -c 'source "$ROOT/config.env"; source "$ROOT/lib.sh"; source "$1"' _ "$s"
done

ok "terminé"
