{
  nsign,
  meta-sifive,
  opensbi,
  stdenvNoCC,
  fetchFromGitHub,
}:

let
  p550-bin = fetchFromGitHub {
    owner = "sifiveinc";
    repo = "hifive-premier-p550-tools";
    rev = "a0d52ef83c9f0ac120a10bd59b77c6c88466e167";
    hash = "sha256-V/3uUXgRpXb7jWM3x9c7vQDPNrzFhlS2kUECJ6k5rJs=";
  };

  nsignCfg = "${meta-sifive}/recipes-bsp/bootchain/files/nsign.cfg";
  secondBootFw = "${p550-bin}/second_boot_fw/second_boot_fw.bin";
  ddrFw = "${p550-bin}/ddr-fw/ddr_fw.bin";
  payload = "${opensbi}/share/opensbi/lp64/eswin/eic770x/firmware/fw_payload.bin";
in
stdenvNoCC.mkDerivation {
  name = "bootloader_ddr5_secboot";

  nativeBuildInputs = [ nsign ];

  buildPhase = ''
    cp ${secondBootFw} .
    cp ${ddrFw} .
    cp ${payload} .

    nsign ${nsignCfg}
  '';

  installPhase = ''
    mkdir -p $out
    mv bootloader_ddr5_secboot.bin $out/
  '';

  phases = [
    "buildPhase"
    "installPhase"
  ];
}
