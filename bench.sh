#!/usr/bin/env bash
# Mesure les performances d'un modèle avec llama-bench et ajoute le résultat à docs/benchmarks.md.
#
#   ./bench.sh ~/models/unsloth/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf
#   ./bench.sh <modèle.gguf> [options llama-bench supplémentaires]
#
# pp = traitement du prompt (tokens/s), tg = génération (tokens/s).
# Mesuré à contexte vide (d=0) puis avec 8k tokens déjà en contexte (d=8192).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/config.env"

model="${1:?usage: $0 <modèle.gguf> [options llama-bench]}"; shift
[[ -f $model ]] || { echo "introuvable : $model" >&2; exit 1; }

bench="$OPT_DIR/llama.cpp-$DEFAULT_BACKEND/bin/llama-bench"
version="$(cat "$OPT_DIR/llama.cpp-$DEFAULT_BACKEND/VERSION" 2>/dev/null || echo '?')"

result="$("$bench" -m "$model" -ngl 99 -fa on -p 512 -n 128 -d 0,8192 -o md "$@")"
echo "$result"

{
  echo
  echo "### $(basename "$model") — $(date +%Y-%m-%d)"
  echo
  echo "llama.cpp \`$version\` ($DEFAULT_BACKEND)${*:+, options : \`$*\`}"
  echo
  echo "$result"
} >> "$ROOT/docs/benchmarks.md"
echo "→ ajouté à docs/benchmarks.md"
