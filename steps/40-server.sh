# Installe llama-swap et le lance comme service systemd utilisateur.
# La config est lue directement depuis le repo (config/llama-swap.yaml) et rechargée à chaud.
#
# Commandes utiles :
#   systemctl --user status llama-swap
#   journalctl --user -u llama-swap -f

prefix="$OPT_DIR/llama-swap-$LLAMA_SWAP_VERSION"
if [[ ! -x $prefix/llama-swap ]]; then
  arch=$(dpkg --print-architecture)   # amd64 | arm64
  url="https://github.com/mostlygeek/llama-swap/releases/download/v$LLAMA_SWAP_VERSION/llama-swap_${LLAMA_SWAP_VERSION}_linux_$arch.tar.gz"
  log "téléchargement de llama-swap v$LLAMA_SWAP_VERSION"
  mkdir -p "$prefix"
  curl -fsSL "$url" | tar -xz -C "$prefix" llama-swap
fi
ln -sfn "$prefix/llama-swap" "$BIN_DIR/llama-swap"
ok "llama-swap v$LLAMA_SWAP_VERSION → $BIN_DIR/llama-swap"

unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"
cat > "$unit_dir/llama-swap.service" <<EOF
# Généré par strix-halo-inference/steps/40-server.sh — ne pas modifier à la main.
[Unit]
Description=llama-swap (llama.cpp, API OpenAI sur $LLAMA_SWAP_LISTEN)
After=network.target

[Service]
Environment=LLAMA_SERVER=$OPT_DIR/llama.cpp-$DEFAULT_BACKEND/bin/llama-server
Environment=MODELS_DIR=$MODELS_DIR
ExecStart=$BIN_DIR/llama-swap --config $ROOT/config/llama-swap.yaml --listen $LLAMA_SWAP_LISTEN --watch-config
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
ok "service $unit_dir/llama-swap.service"

systemctl --user daemon-reload
systemctl --user enable llama-swap.service >/dev/null

# Un autre programme (ex. un llama-server lancé à la main) sur le même port empêcherait le démarrage.
port=${LLAMA_SWAP_LISTEN##*:}
if ss -Hltnp "sport = :$port" | grep -v llama-swap | grep -q .; then
  warn "le port $port est déjà utilisé : $(ss -Hltnp "sport = :$port" | grep -o 'users:.*')"
  warn "libérer le port puis : systemctl --user restart llama-swap"
else
  systemctl --user restart llama-swap.service
  ok "llama-swap démarré sur http://$LLAMA_SWAP_LISTEN (UI : /ui) — chargement des modèles en cours"
fi

# Démarrage au boot sans session ouverte (utile en accès SSH).
if [[ $LLAMA_SWAP_LINGER == 1 && $(loginctl show-user "$USER" -p Linger --value 2>/dev/null) != yes ]]; then
  log "activation du démarrage sans session (loginctl enable-linger)"
  loginctl enable-linger "$USER" || sudo loginctl enable-linger "$USER"
fi
