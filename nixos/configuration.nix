{ config, ... }:

{
  imports = [
    ./hardware.nix
    ./image.nix
  ];

  networking.hostName = "slicefive";

  # Enable Nix Flakes by default
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Set empty root password for initial setup
  users.users.root.password = "";
  # Allow insecure root login via SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
  };
  networking.firewall.allowedTCPPorts = config.services.openssh.ports;

  system.stateVersion = "26.11";
}
