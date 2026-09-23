{
  sources ? import ./npins,
  system ? builtins.currentSystem,
  nixpkgs ? sources.nixpkgs,
  pkgs ? import nixpkgs {
    inherit system;
    overlays = [ (import ./overlay.nix) ];
  },
}:

let
  mkImage =
    kernel:
    (import "${nixpkgs}/nixos/" {
      system = null;
      configuration = (
        { lib, pkgs, ... }: {
          imports = [
            ./nixos/configuration.nix
          ];
          nixpkgs.buildPlatform = system;
          boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (pkgs.callPackage kernel { }));
        }
      );
    }).config.system.build.sdImage;
in
{
  overlays.default = import ./overlay.nix;

  nixosModules = {
    default = ./nixos/default.nix;
    fstab = ./nixos/fstab.nix;
    hardware = ./nixos/hardware.nix;
    image = ./nixos/image.nix;
  };

  packages = {
    nixosImage = mkImage ./kernels/linux-6.6.nix;
    nixosImage_6_12 = mkImage ./kernels/linux-6.12.nix;

    inherit (pkgs)
      nsign
      bootchainPremierP550
      ubootPremierP550
      opensbiPremierP550
      linuxPremierP550_6_6
      linuxPremierP550_6_12
      ;
  };
}
