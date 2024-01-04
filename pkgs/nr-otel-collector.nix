{
  pkgs,
  stdenv,
  fetchFromGitHub,
  ocb,
}:
stdenv.mkDerivation rec {
  name = "nr-otel-collector";
  version = "0.6.0";
  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "opentelemetry-collector-releases";
    rev = "nr-otel-collector-${version}";
    hash = "sha256-gSyYM4ryI4c48toAEXC1YtKCNXzAwWRHx7enjMZii+4=";
  };

  nativeBuildInputs = with pkgs;
    [
      gnumake
      go
    ]
    ++ [
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
