{
  description = "NixOS on HiFive Premier P550";

  outputs =
    { ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );
    in
    {
      inherit (import ./default.nix { }) nixosModules overlays;

      packages = forAllSystems (system: (import ./default.nix { inherit system; }).packages);

      templates.default = {
        path = ./template;
        description = "Quickstart NixOS remote cross compiled deployment on board";
      };

      devShells = forAllSystems (system: {
        default = import ./shell.nix { inherit system; };
      });
    };
}
