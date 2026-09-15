{
  fetchFromGitHub,
  buildUBoot,
  lib,
}:

let
  src = fetchFromGitHub {
    owner = "eswincomputing";
    repo = "u-boot";
    rev = "f4f474966cc706b5e58bf2550767afc785270adc";
    hash = "sha256-VE/Xgw8s97ClX0vhpaLw+oOtpDN+i227Jd339A9FwHc=";
  };

  extraPatches = [
    ./uBoot/0001-riscv-hifive_premier_p550-Update-boot-media-sequence.patch
  ];

  makefile = "${src}/Makefile";
  version = toString (builtins.match ".+VERSION = ([0-9]+).+" (builtins.readFile makefile));
  patchlevel = toString (builtins.match ".+PATCHLEVEL = ([0-9]+).+" (builtins.readFile makefile));
  sublevel = toString (builtins.match ".+SUBLEVEL = ([0-9]+).+" (builtins.readFile makefile));
  extraversion = toString (
    builtins.match ".+EXTRAVERSION = ([a-z0-9-]+).+" (builtins.readFile makefile)
  );
in
buildUBoot {
  inherit src;
  version = "${version}.${patchlevel}${(lib.optionalString (sublevel != "") ".${sublevel}")}${
    (lib.optionalString (extraversion != "") extraversion)
  }";

  defconfig = "hifive_premier_p550_defconfig";
  inherit extraPatches;

  filesToInstall = [
    "u-boot.bin"
    "u-boot.dtb"
  ];

  extraMeta = {
    platforms = lib.platforms.riscv64;
  };
}
