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
        pkgs.callPackage (
          {
            stdenv,
            dosfstools,
            util-linux,
            libfaketime,
            mtools,
            xz,
            jq,
          }:

          stdenv.mkDerivation {
            name = "nixos.img.xz"; # FIXME:

            nativeBuildInputs = [
              util-linux
              dosfstools
              libfaketime
              mtools
              xz
              jq
            ];

            buildCommand = ''
              # Create empty file
              truncate -s 8G nixos.img

              # Format to GPT (single partition is sufficient)
              sfdisk --no-reread --no-tell-kernel nixos.img << EOF
                label: gpt
                label-id: 5021a652-edb8-44fa-bd34-c7781f5b7c46

                size=1G,type=U
                type=L
              EOF

              # Copy the rootfs into the image
              eval $(partx nixos.img -o START,SECTORS --nr 2 --pairs)
              dd conv=notrunc if=${rootfs} of=nixos.img seek=$START count=$SECTORS

              # Prepare ESP/EFI partition
              eval $(partx nixos.img -o START,SECTORS --nr 1 --pairs)
              truncate -s $((SECTORS * 512)) esp.img
              mkfs.vfat --invariant -n EFI esp.img

              mkdir esp
              ################################################################
              toEspName() {
                local file="$(realpath "$1")"
                local base="$(basename "$file")"
                local dir="$(dirname "$file")"
                local dirbase="$(basename "$dir")"
                echo -n "$dirbase-$base"
              }

              mkdir -p esp/EFI/BOOT esp/EFI/nixos esp/loader/entries
              cp "${bootloader}" "esp/EFI/BOOT/BOOT${bootloaderDest}"
              echo "type1" > esp/loader/entries.srel

              dtb="$(jq -r '.["org.nixos.systemd-boot"].devicetree' ${toplevel}/boot.json)"

              kernelDest="$(toEspName "${toplevel}/kernel")"
              initrdDest="$(toEspName "${toplevel}/initrd")"
              dtbDest="$(toEspName $dtb)"

              cp --no-preserve=mode "${toplevel}/kernel" "esp/EFI/nixos/$kernelDest"
              cp --no-preserve=mode "${toplevel}/initrd" "esp/EFI/nixos/$initrdDest"
              cp --no-preserve=mode "$dtb" "esp/EFI/nixos/$dtbDest"

              cat > esp/loader/entries/initial-nixos.conf <<END
              title NixOS
              version 0
              linux /efi/nixos/$kernelDest
              initrd /efi/nixos/$initrdDest
              devicetree /efi/nixos/$dtbDest
              options init=${toplevel}/init $(cat ${toplevel}/kernel-params)
              END

              cp --no-preserve=mode -r ${config.hardware.deviceTree.package} esp/dtbs
              ################################################################
              # TODO: populateEspCommandsPath

              # Copy all files into ESP
              find esp -exec touch --date=2000-01-01 {} +
              cd esp
              # Force a fixed order in mcopy for better determinism, and avoid file globbing
              for d in $(find . -type d -mindepth 1 | sort); do
                faketime "2000-01-01 00:00:00" mmd -i ../esp.img "::/$d"
              done
              for f in $(find . -type f | sort); do
                mcopy -pvm -i ../esp.img "$f" "::/$f"
              done
              cd ..

              # Verify ESP and copy into image
              fsck.vfat -vn esp.img
              dd conv=notrunc if=esp.img of=nixos.img seek=$START count=$SECTORS

              # Compress final image
              xz -T $NIX_BUILD_CORES -z nixos.img

              # Output files
              mkdir $out
              mv nixos.img.xz $out/nixos.img.xz
            '';
          }
        ) { };

      systemd.services.register-nix-paths = {
        description = "Register Nix Store Paths";
        unitConfig = {
          DefaultDependencies = false;
          ConditionPathExists = nixPathRegistrationFile;
        };
        wantedBy = [ "sysinit.target" ];
        before = [
          "sysinit.target"
          "shutdown.target"
          "nix-daemon.socket"
          "nix-daemon.service"
        ];
        after = [ "local-fs.target" ];
        conflicts = [ "shutdown.target" ];
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${lib.getExe' config.nix.package.out "nix-store"} --load-db < ${nixPathRegistrationFile}

          # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
          touch /etc/NIXOS
          ${lib.getExe' config.nix.package.out "nix-env"} -p /nix/var/nix/profiles/system --set /run/current-system

          # Prevents this from running on later boots.
          rm -f ${nixPathRegistrationFile}
        '';
      };
    };
}
