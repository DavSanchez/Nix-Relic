{
  lib,
  pkgs,
  stdenv,
  ocb,
  sourceSrc,
  sourceName,
  sourceVersion,
}:
stdenv.mkDerivation {
  name = "${sourceName}-${sourceVersion}-sources";
  src = sourceSrc;
  nativeBuildInputs = with pkgs; [gnumake go curl] ++ [ocb];
  buildPhase = ''
    # script run by make needs the correct bash location
    patchShebangs ./scripts/build.sh

    export HOME=$TMPDIR
    chmod -R u+w .
    make generate-sources
  '';
  installPhase = ''
    # Remove log files as they make the build non-reproducible (contains dates)
    rm -rf distributions/nr-otel-collector/_build/build.log
    cp -r distributions/nr-otel-collector/_build/ $out
  '';
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "sha256-vGjyIGRKzC4MQIWA3zXLK4kUXK+9B819rxGEilUukhA=";
}
