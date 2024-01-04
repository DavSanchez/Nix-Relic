{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  buildGoModule,
  ocb,
}: let
  distName = "nr-otel-collector";
  distVersion = "0.6.0";
in
  stdenv.mkDerivation {
    name = "collector-dist-${distVersion}";
    src = fetchFromGitHub {
      owner = "newrelic";
      repo = "opentelemetry-collector-releases";
      rev = "nr-otel-collector-${distVersion}";
      hash = "sha256-gSyYM4ryI4c48toAEXC1YtKCNXzAwWRHx7enjMZii+4=";
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
      # Remove log files as they make the build non-reproducible (contains dates)
      rm -rf distributions/nr-otel-collector/_build/build.log
      cp -r distributions/nr-otel-collector/_build/ $out
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-vGjyIGRKzC4MQIWA3zXLK4kUXK+9B819rxGEilUukhA=";
  }
