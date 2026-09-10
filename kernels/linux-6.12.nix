{
  buildLinux,
  fetchFromGitHub,
  lib,
  ...
}@args:

let
  # Branch rel/kernel-6.12/hifive-premier-p550
  src = fetchFromGitHub {
    owner = "sifiveinc";
    repo = "riscv-linux";
    rev = "3340c5ae8c9d093fdf23ed8c68437846cac893b6";
    hash = "sha256-1bkLMnsd5XoYuWZANBBF0et9LuvZMe5QexMfmpRJQqQ=";
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
