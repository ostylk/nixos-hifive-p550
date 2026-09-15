{
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation {
  pname = "esbd-77serial-nsign";
  version = "dev";

  src = fetchFromGitHub {
    owner = "eswincomputing";
    repo = "Esbd-77serial-nsign";
    rev = "74e7c69b812923f68ef3eeb0c1cbbee90f80b566";
    hash = "sha256-qh0PXMzWHVnJ2eAgwf8ATfo8dvykf9RkjFjWyAhIYAY=";
  };

  nativeBuildInputs = [ cmake ];
}
