{
  pkgs,
  stdenv,
  fetchFromGitHub,
  ocb
}:
stdenv.mkDerivation {
  name = "nr-otel-collector";
  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "opentelemetry-collector-releases";
    rev = "nr-otel-collector-0.5.0";
    hash = "sha256-h6qxPDdKkyX8/GhOm/V/RfexnV/mbwmQ2hhFJDOXQaY=";
  };

  nativeBuildInputs = with pkgs; [
    gnumake
    go
  ] ++ [
    ocb
  ];

  buildPhase = ''
    # script run by make needs the correct bash location
    patchShebangs ./scripts/build.sh

    # for Go's GOPATH, mod cache, etc
    export HOME=$TMPDIR

    make build
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp distributions/nr-otel-collector/_build/nr-otel-collector $out/bin/

    runHook postInstall
  '';
}
