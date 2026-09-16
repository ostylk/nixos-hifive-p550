# TODOs
- Refactor image creation
- Linux image is 107MB big (defconfig uses no modules, everything compiled in)

# References
- Image Generation code largely based on/copied from [dramforever/nixos-riscv-efi](https://github.com/dramforever/nixos-riscv-efi) and [`sd-image.nix`](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/sd-card/sd-image.nix)
- For comparing/fixing kernel configuration [MatthewCroughan/nixos-p550](https://github.com/MatthewCroughan/nixos-p550)
