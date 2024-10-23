{
  lib,
  pkgs,
  buildGoModule,
  fetchFromGitHub,
  opentelemetry-collector-builder,
}:
let
  pinnedOcbVersion = opentelemetry-collector-builder.override {
    buildGoModule =
      previousArgs:
      buildGoModule (
        previousArgs
        // rec {
          version = "0.108.0";
          src = fetchFromGitHub {
            owner = "open-telemetry";
            repo = "opentelemetry-collector";
            rev = "cmd/builder/v${version}";
            sha256 = "sha256-hLC9vB+xAwSuqaO1h3qPPofUTa+L2Mdh6xXHq2bBSFc=";
            fetchSubmodules = true;
          };
          vendorHash = "sha256-5lXa99nH2yDxd1MHUCqG9o7bEK6/Ia40kvnm+67VTNU=";
        }
      );
  };
in
buildGoModule rec {
  pname = "nr-otel-collector";
  version = "0.8.3";

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "opentelemetry-collector-releases";
    rev = "${pname}-${version}";
    sha256 = "sha256-tUuNqaI92M2JVTI5Y5tEAe0ocPlNGxt+9v5Y84pGnrs=";
  };

  # Generate the distribution sources
  preConfigure = ''
    patchShebangs ./scripts/build.sh

    export HOME=$TMPDIR
    chmod -R u+w .

    ./scripts/build.sh -d "nr-otel-collector" -s true -b "${pinnedOcbVersion}/bin/ocb" -g "${pkgs.go}/bin/go"
  '';

  # The generated distribution sources end up in this location.
  # This is the actual Go module we will build
  modRoot = "distributions/nr-otel-collector/_build";

  vendorHash = "sha256-CV+Azc/dEYLun1LxAixtC7s7Z+ijTdwGwrjo8UHPAYw=";

  ldflags = [
    "-s"
    "-w"
  ];

  # The TestGenerateAndCompile tests download new dependencies for a modified go.mod. Nix doesn't allow network access so skipping.
  checkFlags = [ "-skip TestValidateConfigs" ];

  CGO_ENABLED = "0";

  meta = with lib; {
    description = "The New Relic distribution of the OpenTelemetry Collector";
    homepage = "https://github.com/newrelic/opentelemetry-collector-releases.git";
    license = licenses.asl20;
    maintainers = with maintainers; [ DavSanchez ];
    mainProgram = "nr-otel-collector";
    platforms = platforms.all;
  };
}
