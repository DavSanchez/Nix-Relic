{
  lib,
  pkgs,
  buildGoModule,
  fetchFromGitHub,
  opentelemetry-collector-builder,
}:
let
  distName = "nrdot-collector";
  # ocb generates the distribution sources into distributions/${distName}/_build.
  # This must run in both the main derivation (preConfigure) and the
  # go-modules derivation (modConfigurePhase), since each gets its own copy of src.
  generateSources = ''
    export HOME=$TMPDIR
    chmod -R u+w .

    (
      cd distributions/${distName}
      mkdir -p _build
      ocb --skip-compilation=true --config manifest.yaml > _build/build.log 2>&1
      rm -f _build/build.log
    )
  '';
in
buildGoModule rec {
  pname = distName;
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "nrdot-collector-releases";
    rev = version;
    hash = "sha256-zM8xmTZdUB1dX4062XOhLzWYYOg471/U7GIPny13I1Q=";
  };

  # Generate the distribution sources with the OpenTelemetry Collector Builder
  nativeBuildInputs = [
    opentelemetry-collector-builder
    pkgs.gnumake
  ];

  preConfigure = generateSources;

  # Same generation step for the go-modules derivation, which does not inherit preConfigure
  modConfigurePhase = ''
    ${generateSources}
    cd "$modRoot"
  '';

  # The generated distribution sources end up in this location.
  # This is the actual Go module we will build
  modRoot = "distributions/${distName}/_build";

  vendorHash = "sha256-WxbDR0OumDVpKw2XtZ3bTxc8hPT2ChCs22MFlhP3nlg=";

  ldflags = [
    "-s"
    "-w"
  ];

  # The TestValidateConfigs tests download new dependencies for a modified go.mod. Nix doesn't allow network access so skipping.
  checkFlags = [ "-skip TestValidateConfigs" ];

  env.CGO_ENABLED = "0";

  meta = with lib; {
    description = "The New Relic distribution of the OpenTelemetry Collector";
    homepage = "https://github.com/newrelic/nrdot-collector-releases.git";
    changelog = "https://github.com/newrelic/nrdot-collector-releases/blob/${src.rev}/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ DavSanchez ];
    mainProgram = "nrdot-collector";
    platforms = platforms.all;
  };
}
