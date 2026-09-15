{
  description = "New development project. TODO: change.";

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
        hardware = import ./nixos/hardware.nix;
      };

      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/configuration.nix
        ];
      };

      packages = builtins.mapAttrs (system: pkgs: {
        linux-6_6 = pkgs.pkgsCross.riscv64.callPackage ./kernels/linux-6.6.nix { };
        linux-6_12 = pkgs.pkgsCross.riscv64.callPackage ./kernels/linux-6.12.nix { };

        uBoot = pkgs.pkgsCross.riscv64.callPackage ./packages/uBoot.nix {
          inherit (inputs) meta-sifive;
        };

        opensbi = pkgs.pkgsCross.riscv64.callPackage ./packages/opensbi.nix {
          inherit (inputs) meta-sifive;
          inherit (self.packages.${system}) uBoot;
        };

        nixos =
          (nixpkgs.lib.nixosSystem {
            specialArgs = { inherit inputs; };
            modules = [
              ./nixos/configuration.nix
              { nixpkgs.buildPlatform = system; }
            ];
          }).config.system.build.sdImage;
      }) nixpkgs.legacyPackages;

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
