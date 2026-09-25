# Benchmarks

Framework Desktop — Ryzen AI MAX+ 395 / Radeon 8060S, 128 Go (96 Go VRAM dédiée), Ubuntu 26.04.
Résultats ajoutés par [`bench.sh`](../bench.sh). `pp512` = lecture du prompt, `tg128` = génération, en tokens/s ;
`@ d8192` = mesuré avec 8k tokens déjà en contexte.

### Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf — 2026-09-25

llama.cpp `b11178-10-ge85e15cf6` (vulkan)

| model                          |       size |     params | backend    | ngl |  fa |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --: | --------------: | -------------------: |
| qwen35moe 35B.A3B Q4_K - Medium |  20.81 GiB |    34.66 B | Vulkan     |  99 |   1 |           pp512 |       1501.23 ± 8.75 |
| qwen35moe 35B.A3B Q4_K - Medium |  20.81 GiB |    34.66 B | Vulkan     |  99 |   1 |           tg128 |         60.78 ± 0.23 |
| qwen35moe 35B.A3B Q4_K - Medium |  20.81 GiB |    34.66 B | Vulkan     |  99 |   1 |   pp512 @ d8192 |       1235.50 ± 3.20 |
| qwen35moe 35B.A3B Q4_K - Medium |  20.81 GiB |    34.66 B | Vulkan     |  99 |   1 |   tg128 @ d8192 |         57.06 ± 0.41 |

build: e85e15cf6 (11188)

### gpt-oss-120b-MXFP4.gguf — 2026-09-25

llama.cpp `b11178-10-ge85e15cf6` (vulkan)

| model                          |       size |     params | backend    | ngl |  fa |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --: | --------------: | -------------------: |
| gpt-oss 120B MXFP4 MoE         |  59.02 GiB |   116.83 B | Vulkan     |  99 |   1 |           pp512 |       1033.65 ± 7.85 |
| gpt-oss 120B MXFP4 MoE         |  59.02 GiB |   116.83 B | Vulkan     |  99 |   1 |           tg128 |         55.29 ± 0.07 |
| gpt-oss 120B MXFP4 MoE         |  59.02 GiB |   116.83 B | Vulkan     |  99 |   1 |   pp512 @ d8192 |        771.44 ± 7.07 |
| gpt-oss 120B MXFP4 MoE         |  59.02 GiB |   116.83 B | Vulkan     |  99 |   1 |   tg128 @ d8192 |         50.92 ± 0.28 |

build: e85e15cf6 (11188)
