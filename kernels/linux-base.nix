{
  buildLinux,
  lib,
  src,
  ...
}@args:

let
  makefile = "${src}/Makefile";
  version = toString (builtins.match ".+VERSION = ([0-9]+).+" (builtins.readFile makefile));
  patchlevel = toString (builtins.match ".+PATCHLEVEL = ([0-9]+).+" (builtins.readFile makefile));
  sublevel = toString (builtins.match ".+SUBLEVEL = ([0-9]+).+" (builtins.readFile makefile));
  extraversion = toString (
    builtins.match ".+EXTRAVERSION = ([a-z0-9-]+).+" (builtins.readFile makefile)
  );
in
buildLinux (
  args
  // {
    inherit src;
    version = "${version}.${patchlevel}.${sublevel}${
      (lib.optionalString (extraversion != "") extraversion)
    }";

    defconfig = "hifive-premier-p550_defconfig";

    structuredExtraConfig =
      with lib.kernel;
      {
        SND_SOC_ES8328 = lib.mkForce no;
        SND_SOC_ES8328_I2C = lib.mkForce no;
        SND_SOC_ES8328_SPI = lib.mkForce no;
        ESWIN_MIPI_DSI = lib.mkForce no;
        DRM_IMG_VOLCANIC = lib.mkForce no;

        # The eic7700 fdt does not assign nids to CPUs
        # so the linux kernel panics if NUMA is activated (because of poor vendor code)
        NUMA = lib.mkForce no;

        # ethernet driver seem to only work if compiled-in...
        STMMAC_ETH = lib.mkForce yes;
        STMMAC_PLATFORM = lib.mkForce yes;
        DWMAC_EIC7700 = lib.mkForce yes;
        MOTORCOMM_PHY = lib.mkForce yes;
      }
      // (args.structuredExtraConfig or { });
  }
  // (args.argsOverride or { })
)
