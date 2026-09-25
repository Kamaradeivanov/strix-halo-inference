# Réglages matériel

## État actuel (2026-09-25)

- CPU : AMD Ryzen AI MAX+ 395 (16C/32T)
- GPU : Radeon 8060S (Strix Halo, RDNA 3.5)
- RAM : 128 Go unifiés, **96 Go réservés au GPU dans le BIOS** (~30 Go visibles par l'OS)
- OS : Ubuntu 26.04 LTS, noyau 7.0

## BIOS : allocation VRAM

Réglage actuel : 96 Go de VRAM dédiée. Simple et fiable.

Alternative : VRAM minimale dans le BIOS (512 Mo) et allocation dynamique via GTT,
ce qui permet au GPU d'utiliser jusqu'à ~120 Go tout en laissant la RAM à l'OS quand il ne s'en sert pas.
Paramètres noyau à ajouter dans `/etc/default/grub` (`GRUB_CMDLINE_LINUX_DEFAULT`), puis `sudo update-grub` :

```
ttm.pages_limit=31457280 ttm.page_pool_size=31457280 amdgpu.gttsize=122880
```

(120 Gio = 31457280 pages de 4 Kio.) Non appliqué pour l'instant.

## Performances attendues

La génération est limitée par la bande passante mémoire (~256 Go/s) :
les modèles **MoE** (peu de paramètres actifs par token) sont nettement plus rapides que les gros denses.
