{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  ocb,
}: let
  pname = "nr-otel-collector";
  version = "0.4.0";
  generated-sources = stdenv.mkDerivation {
    name = "generated-sources";
    src = fetchFromGitHub {
      owner = "newrelic";
      repo = "opentelemetry-collector-releases";
      rev = "nr-otel-collector-${version}";
      hash = "sha256-fGcH7rOVqnb0wG1i1lh81eU1/OHqf3/rVdAbCewwhNo=";
    };
    nativeBuildInputs = [ocb pkgs.gnumake pkgs.go];
    buildPhase = ''
      runHook preBuild
      make generate-sources
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall

      ls -lah
      cp -r . $out

      runHook postInstall
    '';
    outputHash = "sha256-ZLARDZltb7ZPt4iLzHkhUesCqGPD88uEJMkeGzVf7Rc=";
  };
in
  stdenv.mkDerivation {
    pname = pname;
    version = version;

    nativeBuildInputs = [ocb pkgs.gnumake pkgs.go];

    configurePhase = ''
       runHook preConfigure

      ls -lah ${generated-sources}

      ls -lah $src

       runHook postConfigure
    '';

    installPhase = ''
      runHook preInstall

      ls -lah .

      cp -r . $out

      runHook postInstall
    '';

    meta = with lib; {
      description = "Handle the configuration files for the OpenTelemetry New Relic distributions";
      homepage = "https://github.com/newrelic/opentelemetry-collector-releases.git";
      license = licenses.asl20;
      maintainers = with maintainers; [];
      mainProgram = "nr-otel-collector";
      platforms = platforms.all;
    };
  }
