{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  buildGoModule,
  ocb,
}: let
  distName = "nr-otel-collector";
  distVersion = "0.4.0";
in
  stdenv.mkDerivation {
    name = "collector-dist-${distVersion}";
    src = fetchFromGitHub {
      owner = "newrelic";
      repo = "opentelemetry-collector-releases";
      rev = "nr-otel-collector-${distVersion}";
      hash = "sha256-fGcH7rOVqnb0wG1i1lh81eU1/OHqf3/rVdAbCewwhNo=";
    };
    nativeBuildInputs = with pkgs; [gnumake go] ++ [ocb];
    buildPhase = ''
      # script run by make needs the correct bash location
      patchShebangs ./scripts/build.sh

      export HOME=$TMPDIR
      chmod -R u+w .
      make generate-sources
    '';
    installPhase = ''
      # Remove log files as they make the build non-reproducible (contain dates)
      rm -rf distributions/nr-otel-collector/_build/build.log
      cp -r distributions/nr-otel-collector/_build/ $out
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-CCmnkPXF6JhUH0Olrv9YQd2cY1gsQ9zcUv9u4Ba3j94=";
  }
