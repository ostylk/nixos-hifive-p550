{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  config =
    let
      nixPathRegistrationFile = "/nix-path-registration";

      rootfs = pkgs.callPackage (import "${inputs.nixpkgs}/nixos/lib/make-ext4-fs.nix") {
        compressImage = false;
        volumeLabel = "rootfs";
        storePaths = [ config.system.build.toplevel ];
      };
    in
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
        };
      };

      system.build.image = config.system.build.sdImage;
      system.build.sdImage =
        let
          toplevel = config.system.build.toplevel;
          efiArch = pkgs.hostPlatform.efiArch;
          bootloader = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          bootloaderDest = "${lib.strings.toUpper efiArch}.EFI";
        in
        pkgs.callPackage ./image/build-image.nix {
          inherit rootfs;
          populateEspCommands = ''
            toEspName() {
              local file="$(realpath "$1")"
              local base="$(basename "$file")"
              local dir="$(dirname "$file")"
              local dirbase="$(basename "$dir")"
              echo -n "$dirbase-$base"
            }

            mkdir -p EFI/BOOT EFI/nixos loader/entries
            cp "${bootloader}" "EFI/BOOT/BOOT${bootloaderDest}"
            echo "type1" > loader/entries.srel

            dtb="$(${pkgs.buildPackages.jq}/bin/jq -r '.["org.nixos.systemd-boot"].devicetree' ${toplevel}/boot.json)"

            kernelDest="$(toEspName "${toplevel}/kernel")"
            initrdDest="$(toEspName "${toplevel}/initrd")"
            dtbDest="$(toEspName $dtb)"

            cp --no-preserve=mode "${toplevel}/kernel" "EFI/nixos/$kernelDest"
            cp --no-preserve=mode "${toplevel}/initrd" "EFI/nixos/$initrdDest"
            cp --no-preserve=mode "$dtb" "EFI/nixos/$dtbDest"

            cat > loader/entries/initial-nixos.conf <<END
            title NixOS
            version 0
            linux /efi/nixos/$kernelDest
            initrd /efi/nixos/$initrdDest
            devicetree /efi/nixos/$dtbDest
            options init=${toplevel}/init $(cat ${toplevel}/kernel-params)
            END
          '';
        };

      boot.postBootCommands = ''
        if [ -f /nix-path-registration ]; then
          set -euo pipefail
          set -x

          # Load nix store paths
          ${lib.getExe' config.nix.package.out "nix-store"} --load-db < ${nixPathRegistrationFile}

          # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
          touch /etc/NIXOS
          ${lib.getExe' config.nix.package.out "nix-env"} -p /nix/var/nix/profiles/system --set /run/current-system

          # Install bootloader from host to get proper systemd-boot config
          # and not the hacked up manual one
          NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot
          rm -f /boot/loader/entries/initial-nixos.conf

          # Prevents this from running on later boots.
          rm -f ${nixPathRegistrationFile}
        fi
      '';
    };
}
