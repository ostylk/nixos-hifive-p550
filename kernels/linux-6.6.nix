{
  callPackage,
  fetchFromGitHub,
  ...
}@args:

callPackage ./linux-base.nix (
  args
  // {
    # Branch rel/kernel/hifive-premier-p550
    src = fetchFromGitHub {
      owner = "sifiveinc";
      repo = "riscv-linux";
      rev = "b4a753400e624a0eba3ec475fba2866dd7efb767";
      hash = "sha256-waTBK0I+/HGCX14ylWauO/1eE1s5NEACwVBS9sznfk0=";
    };
  }
)
