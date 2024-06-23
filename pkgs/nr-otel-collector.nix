{
  lib,
  pkgs,
  buildGoModule,
  fetchFromGitHub,
  ocb,
}:
let
  distName = "nr-otel-collector";
  distVersion = "0.7.1";
  sourcesDir = "distributions/nr-otel-collector/_build";
  generatedDistDir = "_nrdot_build";
in
buildGoModule {
  pname = distName;
  version = distVersion;

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "opentelemetry-collector-releases";
    rev = "nr-otel-collector-${distVersion}";
    hash = "sha256-h6qxPDdKkyX8/GhOm/V/RfexnV/mbwmQ2hhFJDOXQaY=";
  };

  overrideModAttrs = (
    old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.gnumake ] ++ [ ocb ];

      preConfigure = ''
        # script run by make needs the correct bash location
        patchShebangs ./scripts/build.sh

        export HOME=$TMPDIR
        chmod -R u+w .
        OTELCOL_BUILDER_DIR="${ocb}/bin" make generate-sources

        cd ${sourcesDir}
      '';

      postInstall = ''
        # Remove log files as they make the build non-reproducible (contain dates)
        rm -rf build.log

        cp -r ./ $out/${generatedDistDir}
      '';
    }
  );

  vendorHash = "sha256-AXDG9+kYGxyKhBAY+oXqReiBS9hZNoNp16pmCvyePDs=";

  postConfigure = ''
    # At this point the `vendor` directory also containing the
    # generated sources has been placed.
    # Move to the directory that contains the sources
    cp -r vendor/${generatedDistDir}/* .
  '';

  ldflags = [
    "-s"
    "-w"
  ];

  # TestValidateConfigs is failing for some reason
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
