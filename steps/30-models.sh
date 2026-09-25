# Télécharge les modèles listés dans models.txt vers $MODELS_DIR/<repo>/.
# Reprend les téléchargements interrompus ; ignore les fichiers déjà complets.
# Repos privés/gated : exporter HF_TOKEN avant de lancer.

mkdir -p "$MODELS_DIR"
auth=()
[[ -n ${HF_TOKEN:-} ]] && auth=(-H "Authorization: Bearer $HF_TOKEN")

# Liste "<fichier> <taille>" des fichiers d'un repo correspondant à un motif shell.
hf_files() {
  curl -fsSL "${auth[@]}" "https://huggingface.co/api/models/$1?blobs=true" \
    | python3 -c '
import json, sys, fnmatch
pattern = sys.argv[1]
for s in json.load(sys.stdin)["siblings"]:
    if fnmatch.fnmatch(s["rfilename"], pattern):
        print(s["rfilename"], s.get("size") or 0)
' "$2"
}

while read -r repo pattern; do
  [[ -z $repo || $repo == \#* ]] && continue
  dest="$MODELS_DIR/$repo"
  mapfile -t files < <(hf_files "$repo" "$pattern")
  ((${#files[@]})) || die "$repo : aucun fichier ne correspond à '$pattern'"
  for entry in "${files[@]}"; do
    file=${entry% *} size=${entry##* }
    out="$dest/$file"
    if [[ -f $out && $(stat -c %s "$out") == "$size" ]]; then
      ok "$repo/$file déjà présent"
      continue
    fi
    log "$repo/$file ($((size / 1000000000)) Go)"
    mkdir -p "$(dirname "$out")"
    curl -fL --retry 5 --retry-delay 5 -C - "${auth[@]}" -o "$out" \
      "https://huggingface.co/$repo/resolve/main/$file"
  done
done < <(sed 's/#.*//' "$ROOT/models.txt")
