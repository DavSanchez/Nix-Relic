{
  lib,
  pkgs,
  go,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "ocb";
  version = "0.91.0";
  modRoot = "cmd/builder";

  src = fetchFromGitHub {
    owner = "open-telemetry";
    repo = "opentelemetry-collector";
    rev = "cmd/builder/v${version}";
    hash = "sha256-PHxQD+9cJGfCE6Cr7nYKt5n2lrTzIfUdsLvkprlNNBg=";
    fetchSubmodules = true;
  };

  vendorHash = "sha256-qhX5qwb/NRG8Tf2z048U6a8XysI2bJlUtUF+hfBtx4Q=";

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
