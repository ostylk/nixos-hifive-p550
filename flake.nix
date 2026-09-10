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
  };

  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
      ...
    }@inputs:
    {
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
