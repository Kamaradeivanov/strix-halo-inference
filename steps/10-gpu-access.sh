# Accès utilisateur au GPU (/dev/dri, /dev/kfd).
# En session graphique locale, logind donne déjà l'accès (ACL). Les groupes sont
# nécessaires pour SSH et pour les services systemd (llama-server).

for grp in render video; do
  if id -nG "$USER" | tr ' ' '\n' | grep -qx "$grp"; then
    ok "$USER est dans le groupe $grp"
  else
    log "ajout de $USER au groupe $grp (effectif à la prochaine connexion)"
    sudo usermod -aG "$grp" "$USER"
  fi
done
