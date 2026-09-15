{
  fetchFromGitHub,
  buildUBoot,
  lib,
  meta-sifive,
}:

let
  src = fetchFromGitHub {
    owner = "eswincomputing";
    repo = "u-boot";
    rev = "6c8f710028e52709b29b70809131509f2edfb1e5";
    hash = "sha256-jaHsfVjosP+WOui5Y+zDF9Pt1hfaWi0On+aYPdU7mjQ=";
  };

  extraPatches = map (elem: "${meta-sifive}/recipes-bsp/u-boot/u-boot-sifive-hf-prem/${elem}") (
    builtins.attrNames (builtins.readDir "${meta-sifive}/recipes-bsp/u-boot/u-boot-sifive-hf-prem")
  );

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
