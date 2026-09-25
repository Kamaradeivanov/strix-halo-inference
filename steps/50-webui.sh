# Open WebUI (interface de chat branchée sur llama-swap) + SearXNG (recherche web).
# Deux conteneurs podman rootless, lancés par systemd via Quadlet.
#
#   Open WebUI : http://localhost:$OPEN_WEBUI_PORT  (le premier compte créé devient admin)
#   SearXNG    : http://localhost:$SEARXNG_PORT
#
#   systemctl --user status open-webui searxng
#   journalctl --user -u open-webui -f
#
# Les réglages ENABLE_WEB_SEARCH, WEB_SEARCH_* ... ne s'appliquent qu'au premier démarrage :
# ensuite Open WebUI les garde en base et ils se modifient dans Paramètres admin.

command -v podman >/dev/null || apt_install podman

mkdir -p "$STATE_DIR/searxng"
chmod 700 "$STATE_DIR"

# --- Secrets (générés une seule fois) ---------------------------------------------
webui_env="$STATE_DIR/open-webui.env"
if [[ ! -f $webui_env ]]; then
  umask 077
  echo "WEBUI_SECRET_KEY=$(openssl rand -hex 32)" > "$webui_env"
  ok "secret Open WebUI généré dans $webui_env"
fi
searxng_secret_file="$STATE_DIR/searxng/.secret_key"
[[ -f $searxng_secret_file ]] || (umask 077; openssl rand -hex 32 > "$searxng_secret_file")
sed "s/__SECRET_KEY__/$(cat "$searxng_secret_file")/" "$ROOT/config/searxng/settings.yml" \
  > "$STATE_DIR/searxng/settings.yml"
chmod 644 "$STATE_DIR/searxng/settings.yml"

# --- Unités Quadlet -------------------------------------------------------------------
quadlet_dir="$HOME/.config/containers/systemd"
mkdir -p "$quadlet_dir"

cat > "$quadlet_dir/searxng.container" <<EOF
# Généré par strix-halo-inference/steps/50-webui.sh — ne pas modifier à la main.
[Unit]
Description=SearXNG (recherche web pour Open WebUI)

[Container]
Image=$SEARXNG_IMAGE
ContainerName=searxng
PublishPort=127.0.0.1:$SEARXNG_PORT:8080
Volume=$STATE_DIR/searxng/settings.yml:/etc/searxng/settings.yml:ro
Environment=SEARXNG_BASE_URL=http://127.0.0.1:$SEARXNG_PORT/

[Service]
Restart=on-failure
TimeoutStartSec=600

[Install]
WantedBy=default.target
EOF

# Réseau "host" : le conteneur joint llama-swap (127.0.0.1:8080) et SearXNG directement,
# et n'écoute lui-même que sur 127.0.0.1.
cat > "$quadlet_dir/open-webui.container" <<EOF
# Généré par strix-halo-inference/steps/50-webui.sh — ne pas modifier à la main.
[Unit]
Description=Open WebUI (chat sur llama-swap)
Wants=searxng.service
After=searxng.service llama-swap.service

[Container]
Image=$OPEN_WEBUI_IMAGE
ContainerName=open-webui
Network=host
Volume=open-webui:/app/backend/data
EnvironmentFile=$webui_env
Environment=HOST=127.0.0.1
Environment=PORT=$OPEN_WEBUI_PORT
Environment=ENABLE_OLLAMA_API=False
Environment=OPENAI_API_BASE_URL=http://${LLAMA_SWAP_LISTEN}/v1
Environment=OPENAI_API_KEY=none
Environment=ENABLE_WEB_SEARCH=True
Environment=WEB_SEARCH_ENGINE=searxng
Environment=SEARXNG_QUERY_URL=http://127.0.0.1:$SEARXNG_PORT/search?q=<query>
Environment=WEB_SEARCH_RESULT_COUNT=5
Environment=ANONYMIZED_TELEMETRY=False
Environment=DO_NOT_TRACK=True
Environment=SCARF_NO_ANALYTICS=True

[Service]
Restart=on-failure
TimeoutStartSec=900

[Install]
WantedBy=default.target
EOF
ok "unités Quadlet dans $quadlet_dir"

# --- Images et démarrage -----------------------------------------------------------
for image in "$SEARXNG_IMAGE" "$OPEN_WEBUI_IMAGE"; do
  if ! podman image exists "$image"; then
    log "téléchargement de $image"
    podman pull -q "$image" >/dev/null
  fi
done

systemctl --user daemon-reload
systemctl --user restart searxng.service open-webui.service
ok "SearXNG sur http://127.0.0.1:$SEARXNG_PORT, Open WebUI sur http://127.0.0.1:$OPEN_WEBUI_PORT (1er démarrage : ~1 min)"
