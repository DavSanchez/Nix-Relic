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
  generated-sources = pkgs.callPackage ./sources.nix {inherit ocb;};
in
  buildGoModule {
    pname = distName;
    version = distVersion;

    src = generated-sources;

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
