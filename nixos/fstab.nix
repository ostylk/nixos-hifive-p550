{ ... }:

{
  boot.growPartition = true;
  fileSystems = {
    "/" = {
      label = "rootfs";
      fsType = "ext4";
      autoResize = true;
    };
    "/boot" = {
      label = "EFI";
      fsType = "vfat";
      neededForBoot = true;
    };
  };
}
