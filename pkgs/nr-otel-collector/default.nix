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
  generated-sources = pkgs.callPackage ./sources.nix { inherit ocb;};
in
  buildGoModule {
    pname = distName;
    version = distVersion;

    src = generated-sources;

    vendorHash = "sha256-IfKYw8jp5Z64qy/gWVo+UjojdGqrIGOEmQz8u81Zwc4=";

    ldflags = [
      "-s"
      "-w"
    ];

    CGO_ENABLED = "0";

    meta = with lib; {
      description = "The New Relic distribution of the OpenTelemetry Collector";
      homepage = "https://github.com/newrelic/opentelemetry-collector-releases.git";
      license = licenses.asl20;
      maintainers = with maintainers; [DavSanchez];
      mainProgram = "nr-otel-collector";
      platforms = platforms.all;
    };
  }
