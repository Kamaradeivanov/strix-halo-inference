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
| `90-check` | VRAM, Vulkan, détection du GPU par llama.cpp |

Toutes les étapes sont idempotentes. `./setup.sh 20` relance uniquement la compilation (utile pour mettre à jour llama.cpp).

## Configuration

Voir [config.env](config.env). Pour épingler une version de llama.cpp :

```bash
LLAMA_CPP_REF=b6500 ./setup.sh 20
```

La version compilée est notée dans `~/.local/opt/llama.cpp-vulkan/VERSION`.

## Réglages matériel (hors script)

Voir [docs/hardware.md](docs/hardware.md).
