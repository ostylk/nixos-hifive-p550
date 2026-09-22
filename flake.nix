{
  description = "NixOS on HiFive Premier P550";

  inputs = {
    # Nixpkgs
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    # Use pre-commit-hooks to run linters/checks etc.
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "";
    };
    # Contains patches for u-boot and opensbi and additionally a config for the bootchain image.
    # If you update this input be prepared to also update u-boot and opensbi refs.
    meta-sifive = {
      url = "github:sifive/meta-sifive?ref=rel/meta-sifive/hifive-premier-p550";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
      ...
    }@inputs:
    {
      nixosModules = {
        default = {
          imports = [
            ./nixos/fstab.nix
            ./nixos/hardware.nix
          ];
        };
        fstab = ./nixos/fstab.nix;
        hardware = ./nixos/hardware.nix;
        image = ./nixos/image.nix;
      };

      templates.default = {
        path = ./template;
        description = "Quickstart NixOS remote cross compiled deployment on board";
      };

      packages = builtins.mapAttrs (
        system: pkgs:
        let
          mkImage =
            kernel:
            (nixpkgs.lib.nixosSystem {
              specialArgs = { inherit inputs; };
              modules = [
                ./nixos/configuration.nix
                (
                  { lib, pkgs, ... }:
                  {
                    nixpkgs.buildPlatform = system;
                    boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (pkgs.callPackage kernel { }));
                  }
                )
              ];
            }).config.system.build.sdImage;
        in
        {
          linux-6_6 = pkgs.pkgsCross.riscv64.callPackage ./kernels/linux-6.6.nix { };
          linux-6_12 = pkgs.pkgsCross.riscv64.callPackage ./kernels/linux-6.12.nix { };

          nixosImage = mkImage ./kernels/linux-6.6.nix;
          nixosImage6_12 = mkImage ./kernels/linux-6.12.nix;

          uBoot = pkgs.pkgsCross.riscv64.callPackage ./packages/uBoot.nix { };

          opensbi = pkgs.pkgsCross.riscv64.callPackage ./packages/opensbi.nix {
            inherit (inputs) meta-sifive;
            inherit (self.packages.${system}) uBoot;
          };

          nsign = pkgs.callPackage ./packages/nsign.nix { };

          bootchain = pkgs.callPackage ./packages/bootchain.nix {
            inherit (inputs) meta-sifive;
            inherit (self.packages.${system}) opensbi nsign;
          };
        }
      ) nixpkgs.legacyPackages;

      checks = builtins.mapAttrs (system: pkgs: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # Format nix files
            nixfmt.enable = true;
            # Don't accidentally commit merge conflits
            check-merge-conflicts.enable = true;
            # Fix line-endings and eofs
            end-of-file-fixer.enable = true;
            mixed-line-endings.enable = true;
          };
        };
      }) nixpkgs.legacyPackages;

      devShells = builtins.mapAttrs (system: pkgs: {
        default =
          let
            pre-commit = self.checks.${system}.pre-commit-check;
          in
          pkgs.mkShell {
            inherit (pre-commit) shellHook;
            buildInputs = pre-commit.enabledPackages;

            packages = [ ];
          };
      }) nixpkgs.legacyPackages;
    };
}
