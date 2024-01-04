{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  buildGoModule,
  ocb,
}:
# For ref: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/go/module.nix
buildGoModule rec {
  name = "nr-otel-collector";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "opentelemetry-collector-releases";
    rev = "${name}-${version}";
    hash = "sha256-gSyYM4ryI4c48toAEXC1YtKCNXzAwWRHx7enjMZii+4=";
  };

  nativeBuildInputs = with pkgs; [
    gnumake
    curl
  ];

  modConfigurePhase = ''
    runHook preConfigure
    export GOCACHE=$TMPDIR/go-cache
    export GOPATH="$TMPDIR/go"
    

    # Download and use a (fixed) version of ocb to generate the actual sources
    make OTELCOL_BUILDER_DIR=$TMPDIR generate-sources

    # Output and remove log files as they make the build non-reproducible (contains dates)
    cat "${modRoot}/build.log"
    rm -rf "${modRoot}/build.log"

    # Copy build generated outputs to final derivation
    cp -r "${modRoot}" $out

    # Continue with fetcher derivation
    cd "${modRoot}"

    runHook postConfigure
  '';

  preBuild = ''
  # where am I?
  ls -lah
  ls -lah ${modRoot}
  '';

  vendorHash = "sha256-uYGBMJ1opLjqvhlcz9B7nFGeLvo2prhlzQt7DY3tDiU=";

  ldflags = [
    "-s"
    "-w"
  ];

  CGO_ENABLED = "0";

  doCheck = false; # FIXME: --- FAIL: TestValidateConfigs (components_test.go:32)

  meta = with lib; {
    description = "The New Relic distribution of the OpenTelemetry Collector";
    homepage = "https://github.com/newrelic/opentelemetry-collector-releases.git";
    license = licenses.asl20;
    maintainers = with maintainers; [DavSanchez];
    mainProgram = "nr-otel-collector";
    platforms = platforms.all;
  };
}
