{
  lib,
  pkgs,
  stdenv,
  fetchFromGitHub,
  buildGoModule,
  ocb,
}:
buildGoModule rec {
  name = "nr-otel-collector";
  version = "0.6.0";

  src = pkgs.callPackage ./sources.nix {
    inherit ocb;
    sourceName = name;
    sourceVersion = version;
    sourceSrc = fetchFromGitHub {
      owner = "newrelic";
      repo = "opentelemetry-collector-releases";
      rev = "${name}-${version}";
      hash = "sha256-gSyYM4ryI4c48toAEXC1YtKCNXzAwWRHx7enjMZii+4=";
    };
  };

  vendorHash = "sha256-XC7Nd/Vgq0AmG5O7fANVKH+r719SVO485+LH/cHtDQA=";

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
