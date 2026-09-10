{ ... }:

{
  imports = [
    ./hardware.nix
  ];

  fileSystems = {
    "/" = {
      label = "rootfs";
      fsType = "ext4";
    };
    "/boot" = {
      label = "EFI";
      fsType = "vfat";
    };
  };

  system.stateVersion = "26.11";
}
