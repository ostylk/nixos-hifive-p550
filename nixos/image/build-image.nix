{
  runCommand,
  dosfstools,
  util-linux,
  libfaketime,
  mtools,
  xz,

  rootfs,
  populateEspCommands,
  imageUuid ? "1dec9de4-6e6b-4460-8c74-1ee4a2f0433e",
  imageSize ? "4G",
  efiPartitionSize ? "1G",
  efiPartitionLabel ? "EFI",
}:

# TODOs:
# 1. Fix derivation name
# 2. Fix output name (c.f. 1)
# 3. Check efiPartition < imageSize  (maybe sfdisk already throws error if that does not work out)
# 4. Check if hardcoded nixos.img and esp.img is good (probably not)
runCommand "nixos.img.xz"
  {
    nativeBuildInputs = [
      util-linux
      dosfstools
      libfaketime
      mtools
      xz
    ];
  }
  ''
    # Create empty file
    truncate -s ${imageSize} nixos.img

    # Format to GPT (EFI and rootfs partition)
    sfdisk --no-reread --no-tell-kernel nixos.img << EOF
      label: gpt
      label-id: ${imageUuid}

      size=${efiPartitionSize},type=U
      type=L
    EOF

    # Copy the rootfs into the image
    eval $(partx nixos.img -o START,SECTORS --nr 2 --pairs)
    dd conv=notrunc if=${rootfs} of=nixos.img seek=$START count=$SECTORS

    # Prepare ESP/EFI partition
    eval $(partx nixos.img -o START,SECTORS --nr 1 --pairs)
    truncate -s $((SECTORS * 512)) esp.img
    mkfs.vfat --invariant -n ${efiPartitionLabel} esp.img

    # Populate the esp directory with files we want to copy onto the partition
    mkdir esp
    cd esp
    ${populateEspCommands}

    # Copy all files into ESP
    # Force a fixed order in mcopy for better determinism, and avoid file globbing
    find . -exec touch --date=2000-01-01 {} +
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

    # Copy to nix store
    mkdir $out
    mv nixos.img.xz $out/nixos.img.xz
  ''
