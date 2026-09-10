{ ... }:

{
  imports = [
    ./hardware.nix
    ./image.nix
  ];

  system.stateVersion = "26.11";
}
