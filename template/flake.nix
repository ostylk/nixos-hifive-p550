{
  description = "NixOS on HiFive Premiere P550";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hifive.url = "github:ostylk/nixos-hifive-p550";
    nixos-hifive.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    colmenaHive = inputs.colmena.lib.makeHive {
      meta = {
        nixpkgs = import inputs.nixpkgs {
          system = "riscv64-unknown-linux-gnu";
          overlays = [ ];
        };
      };

      asterisc = {
        imports = [
          inputs.nixos-hifive.nixosModules.default
        ];

        deployment = {
          # TODO: put your stuff here
          targetHost = "asterisc";
          targetPort = 22;
          targetUser = "root";
          buildOnTarget = false;
        };

        services.openssh = {
          enable = true;
          openFirewall = true;
        };

        users.users.root.openssh.authorizedKeys.keys = [
          # TODO: put your keys here
        ];

        # FIXME: this only allows deployment from x86_64 hosts, idk if colmena supports proper cross compilation
        nixpkgs.buildPlatform = "x86_64-linux";
        system.stateVersion = "26.11";
      };
    };

    devShells = builtins.mapAttrs (system: pkgs: {
      default = pkgs.mkShell {
        name = "deployment-shell";

        packages = [ inputs.colmena.packages.${system}.colmena ];
      };
    }) inputs.nixpkgs.legacyPackages;
  };
}
