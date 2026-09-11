{
  callPackage,
  fetchFromGitHub,
  ...
}@args:

callPackage ./linux-base.nix (
  args
  // {
    # Branch rel/kernel-6.12/hifive-premier-p550
    src = fetchFromGitHub {
      owner = "sifiveinc";
      repo = "riscv-linux";
      rev = "3340c5ae8c9d093fdf23ed8c68437846cac893b6";
      hash = "sha256-1bkLMnsd5XoYuWZANBBF0et9LuvZMe5QexMfmpRJQqQ=";
    };
  }
)
