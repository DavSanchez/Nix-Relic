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

  nativeBuildInputs = with pkgs; [
    gnumake
  ];

  buildPhase = ''
    runHook preBuild
    
    make ocb

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ../../bin/ocb_${go.GOOS}_${go.GOARCH} $out/bin/${pname}

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
