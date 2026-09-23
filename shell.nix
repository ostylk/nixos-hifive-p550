{
  sources ? import ./npins,
  system ? builtins.currentSystem,
  nixpkgs ? sources.nixpkgs,
  pkgs ? import nixpkgs {
    inherit system;
    overlays = [ ];
  },
  pre-commit-hooks ? import "${sources.pre-commit-hooks}/nix" {
    inherit nixpkgs system;
    isFlakes = false;
  },
}:

let
  pre-commit = pre-commit-hooks.run {
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
in
pkgs.mkShell {
  inherit (pre-commit) shellHook;
  packages = pre-commit.enabledPackages;
}
