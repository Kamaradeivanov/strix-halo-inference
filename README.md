# strix-halo-inference

Setup reproductible d'inférence LLM locale sur **Framework Desktop** (AMD Ryzen AI MAX+ 395 / Radeon 8060S, 128 Go) sous **Ubuntu 26.04**.

Moteur : [llama.cpp](https://github.com/ggml-org/llama.cpp) compilé depuis les sources, backend **Vulkan (RADV)**.

## Réinstaller depuis une machine vierge

Prérequis : [distro-bootstrap](https://github.com/Kamaradeivanov/distro-bootstrap) (shell, git, mise).

```bash
git clone git@github.com:Kamaradeivanov/strix-halo-inference.git ~/workspace/fabrique-it/strix-halo-inference
cd ~/workspace/fabrique-it/strix-halo-inference
./setup.sh
```

Les groupes `render`/`video` ne servent qu'en SSH et pour les services (en session locale, l'accès GPU est automatique) :
se reconnecter une fois pour qu'ils soient pris en compte. Vérifier :

```bash
./setup.sh 90
```

## Étapes

| Étape | Rôle |
|---|---|
| `00-packages` | git, outils de compilation, SDK Vulkan, outils de monitoring |
| `10-gpu-access` | ajoute l'utilisateur aux groupes `render` et `video` |
| `20-llama-cpp-vulkan` | clone/compile llama.cpp (Vulkan), installe dans `~/.local/opt/llama.cpp-vulkan`, liens dans `~/.local/bin` |
| `30-models` | télécharge les modèles de [models.txt](models.txt) dans `~/models/<repo>/` (reprise, vérification de taille) |
| `40-server` | installe llama-swap et le service systemd utilisateur `llama-swap` |
| `50-webui` | Open WebUI (chat) + SearXNG (recherche web), conteneurs podman gérés par systemd (Quadlet) |
| `90-check` | VRAM, Vulkan, détection du GPU par llama.cpp |

Toutes les étapes sont idempotentes. `./setup.sh 20` relance uniquement la compilation (utile pour mettre à jour llama.cpp,
puis `systemctl --user restart llama-swap`).

## Utilisation

Le service **llama-swap** expose une API compatible OpenAI sur `http://localhost:8080/v1` et garde les deux modèles
chargés en permanence ([config/llama-swap.yaml](config/llama-swap.yaml), rechargée automatiquement à chaque modification).

| `model` | Modèle | Réglage |
|---|---|---|
| `qwen3.6` | Qwen3.6-35B-A3B | thinking, usage général |
| `qwen3.6:code` | | thinking, code précis |
| `qwen3.6:instruct` | | sans thinking |
| `gpt-oss-120b` | gpt-oss-120b | raisonnement medium |
| `gpt-oss-120b:low` / `:high` | | raisonnement low / high |

```bash
curl -s localhost:8080/v1/chat/completions -H 'Content-Type: application/json' \
  -d '{"model": "qwen3.6:instruct", "messages": [{"role": "user", "content": "Bonjour !"}]}'
```

- Modifier `config/llama-swap.yaml` recharge les modèles (~30 s d'indisponibilité)
- Interface llama-swap : http://localhost:8080/ui (modèles chargés, logs, activité)
- Chat (interface web de llama-server) : http://localhost:8080/upstream/qwen3.6/ et http://localhost:8080/upstream/gpt-oss-120b/
- Service : `systemctl --user status|restart llama-swap`, logs : `journalctl --user -u llama-swap -f`

### Open WebUI

http://localhost:3000 — interface de chat complète branchée sur llama-swap (toutes les variantes dans le menu des modèles),
avec historique, documents et **recherche web** via SearXNG (http://localhost:8888, sans clé d'API).

- Le premier compte créé devient administrateur.
- Recherche web : bouton « Recherche web » sous la zone de saisie (désactivé par défaut dans chaque conversation).
  Pour l'activer d'office : Paramètres admin → Modèles → éditer le modèle → Fonctionnalités par défaut → Recherche web.
- Modèle de tâches (titres, requêtes de recherche) : Paramètres admin → Interface → `qwen3.6:instruct`.
- Les réglages de recherche web ne sont lus qu'au premier démarrage, ensuite : Paramètres admin → Recherche web.
- Services : `systemctl --user status open-webui searxng`. Données : volume podman `open-webui`.
- Secrets générés localement dans `~/.config/strix-halo-inference/` (hors repo).

## Benchmarks

`./bench.sh <modèle.gguf>` — résultats dans [docs/benchmarks.md](docs/benchmarks.md).

## Configuration

Voir [config.env](config.env). Pour épingler une version de llama.cpp :

```bash
LLAMA_CPP_REF=b6500 ./setup.sh 20
```

La version compilée est notée dans `~/.local/opt/llama.cpp-vulkan/VERSION`.

## Réglages matériel (hors script)

Voir [docs/hardware.md](docs/hardware.md).
