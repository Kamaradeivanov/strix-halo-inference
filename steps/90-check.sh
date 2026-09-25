# Vérifie que le GPU est visible et que llama.cpp le détecte.

gpu_dev=$(ls -d /sys/class/drm/card*/device/mem_info_vram_total 2>/dev/null | head -1 || true)
if [[ -n $gpu_dev ]]; then
  dir=$(dirname "$gpu_dev")
  ok "VRAM dédiée : $(( $(cat "$dir/mem_info_vram_total") / 1024**3 )) Gio, GTT : $(( $(cat "$dir/mem_info_gtt_total") / 1024**3 )) Gio"
fi

if ! command -v vulkaninfo >/dev/null; then
  warn "vulkaninfo absent — lancer l'étape 00"
elif vulkaninfo --summary 2>/dev/null | grep -q "deviceName"; then
  ok "Vulkan : $(vulkaninfo --summary 2>/dev/null | grep -m1 deviceName | sed 's/.*= //')"
else
  warn "vulkaninfo ne voit aucun GPU (hors session locale : groupe render requis, reconnexion après l'étape 10)"
fi

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) warn "$BIN_DIR n'est pas dans le PATH (Ubuntu l'ajoute à la prochaine connexion)" ;;
esac

if [[ -x $BIN_DIR/llama-cli ]]; then
  "$BIN_DIR/llama-cli" --list-devices 2>&1 | grep -iE "vulkan|device" || warn "llama-cli ne liste aucun device"
else
  warn "llama-cli absent — lancer l'étape 20"
fi
