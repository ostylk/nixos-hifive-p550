{ ... }:

{
  imports = [
    ./fstab.nix
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
    openFirewall = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      PermitEmptyPasswords = true;
      KbdInteractiveAuthentication = true;
    };
  };
  security.pam.services.sshd.allowNullPassword = true;

  system.stateVersion = "26.11";
}
