{
  buildLinux,
  fetchFromGitHub,
  lib,
  ...
}@args:

let
  # Branch rel/kernel/hifive-premier-p550
  src = fetchFromGitHub {
    owner = "sifiveinc";
    repo = "riscv-linux";
    rev = "b4a753400e624a0eba3ec475fba2866dd7efb767";
    hash = "sha256-waTBK0I+/HGCX14ylWauO/1eE1s5NEACwVBS9sznfk0=";
  };

  makefile = "${src}/Makefile";
  version = toString (builtins.match ".+VERSION = ([0-9]+).+" (builtins.readFile makefile));
  patchlevel = toString (builtins.match ".+PATCHLEVEL = ([0-9]+).+" (builtins.readFile makefile));
  sublevel = toString (builtins.match ".+SUBLEVEL = ([0-9]+).+" (builtins.readFile makefile));
in
buildLinux (
  args
  // {
    inherit src;
    version = "${version}.${patchlevel}.${sublevel}";

    defconfig = "hifive-premier-p550_defconfig";

    structuredExtraConfig = with lib.kernel; {
      SND_SOC_ES8328 = lib.mkForce no;
      SND_SOC_ES8328_I2C = lib.mkForce no;
      SND_SOC_ES8328_SPI = lib.mkForce no;
      ESWIN_MIPI_DSI = lib.mkForce no;
      DRM_IMG_VOLCANIC = lib.mkForce no;
    };
  }
  // (args.argsOverride or { })
)
