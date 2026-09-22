{ pkgs, ... }:

{
  system.nixos.tags = [ "hifive-premier-p550" ];

  # Use kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage ../kernels/linux-6.6.nix { });
  boot.kernelParams = [
    "efi=debug"
    "earlycon=sbi"
  ];

  # This kernel has every necessary module compiled in
  boot.initrd.includeDefaultModules = false;

  # Make sure we use the correct device tree, otherwise the board just won't boot
  hardware.deviceTree = {
    enable = true;
    name = "eswin/eic7700-hifive-premier-p550.dtb";
  };

  # EFI boot seems to be the preferred way to boot.
  # (I did not manage to get it to boot without EFI.)
  boot.loader.systemd-boot = {
    enable = true;
    installDeviceTree = true;
  };

  nixpkgs.hostPlatform = "riscv64-unknown-linux-gnu";
}
