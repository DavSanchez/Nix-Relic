{
  lib,
  pkgs,
  go,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "ocb";
  version = "0.85.0";
  modRoot = "cmd/builder";

  src = fetchFromGitHub {
    owner = "open-telemetry";
    repo = "opentelemetry-collector";
    rev = "cmd/builder/v${version}";
    hash = "sha256-mHuno6meQLWtzP8hGXK37O8SbIyeh3vEvMwwKFM624s=";
    fetchSubmodules = true;
  };

  vendorHash = "sha256-ZLARDZltb7ZPt4iLzHkhUesCqGPD88uEJMkeGzVf7Rc=";

  # Tests perform compilation so they pull external sources, which is not allowed at this point
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
  ];

  installPhase = ''
    # Same as done in buildGoModule, but renaming the binary

    runHook preInstall

    mkdir -p $out
    dir="$GOPATH/bin"
    [ -e "$dir" ] && cp -r $dir $out

    bin_name="builder"
    mv $out/bin/$bin_name $out/bin/${pname}

    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenTelemetry Collector";
    homepage = "https://github.com/open-telemetry/opentelemetry-collector.git";
    changelog = "https://github.com/open-telemetry/opentelemetry-collector/blob/${src.rev}/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [DavSanchez];
    mainProgram = "ocb";
  };
}
