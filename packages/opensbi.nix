{
  lib,
  stdenv,
  fetchFromGitHub,
  python3,
  uBoot,
  meta-sifive,
  withPlatform ? "eswin/eic770x",
  withPayload ? "${uBoot}/u-boot.bin",
  withFDT ? "${uBoot}/u-boot.dtb",
}:

let
  patches = map (elem: "${meta-sifive}/recipes-bsp/opensbi/opensbi-sifive-hf-prem/${elem}") (
    builtins.attrNames (builtins.readDir "${meta-sifive}/recipes-bsp/opensbi/opensbi-sifive-hf-prem")
  );
in
# Code from nixpkgs by-name/op/opensbi/package.nix
stdenv.mkDerivation (finalAttrs: {
  pname = "opensbi";

  version = "1.6";
  src = fetchFromGitHub {
    owner = "riscv-software-src";
    repo = "opensbi";
    rev = "bd613dd92113f683052acfb23d9dc8ba60029e0a";
    hash = "sha256-X3j+4hdNDq36O/vFdlnd/QvDVIkXtvFbheFaZwf4GQY=";
  };

  inherit patches;

  postPatch = ''
    patchShebangs ./scripts
  '';

  nativeBuildInputs = [ python3 ];

  installFlags = [
    "I=$(out)"
  ];

  makeFlags = [
    "PLATFORM_RISCV_ISA=rv64imafdc_zicsr_zifencei"
    "PLATFORM=${withPlatform}"
  ]
  ++ lib.optionals (withPayload != null) [
    "FW_PAYLOAD_PATH=${withPayload}"
  ]
  ++ lib.optionals (withFDT != null) [
    "FW_FDT_PATH=${withFDT}"
  ];

  enableParallelBuilding = true;

  dontStrip = true;
  dontPatchELF = true;

  meta = {
    description = "RISC-V Open Source Supervisor Binary Interface";
    homepage = "https://github.com/riscv-software-src/opensbi";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.riscv64;
  };
})
