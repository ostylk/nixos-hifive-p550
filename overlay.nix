final: prev: {
  meta-sifive = (import ./npins).meta-sifive;

  nsign = final.callPackage ./packages/nsign.nix { };
  bootchainPremierP550 = final.callPackage ./packages/bootchain.nix { };

  ubootPremierP550 = final.pkgsCross.riscv64.callPackage ./packages/uBoot.nix { };
  opensbiPremierP550 = final.pkgsCross.riscv64.callPackage ./packages/opensbi.nix { };
  linuxPremierP550_6_6 = final.pkgsCross.riscv64.callPackage ./kernels/linux-6.6.nix { };
  linuxPremierP550_6_12 = final.pkgsCross.riscv64.callPackage ./kernels/linux-6.12.nix { };
}
