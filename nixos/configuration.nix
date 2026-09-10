{ config, ... }:

{
  imports = [
    ./hardware.nix
    ./image.nix
  ];

  users.users.root.password = "";

  # TODO: we probably don't want this in a public repo

  networking.hostName = "slicefive";

  # Enable Nix Flakes by default
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Basic SSH settings
  services.openssh = {
    enable = true;
  };
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILU0T92rNFExfPnPGubu4LOur3clY/d3Eif97MLD+/f0 ostylk@ark"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDoYdQ9jwZSYtss3H/dIVG/HdK2eZT3431D2IW+wQa1g ostylk@ark-surface"
  ];

  system.stateVersion = "26.11";
}
