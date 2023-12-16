{
  lib,
  pkgs,
  go,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "ocb";
  version = "0.86.0";
  modRoot = "cmd/builder";

  src = fetchFromGitHub {
    owner = "open-telemetry";
    repo = "opentelemetry-collector";
    rev = "cmd/builder/v${version}";
    hash = "sha256-Ucp00OjyPtHA6so/NOzTLtPSuhXwz6A2708w2WIZb/E=";
    fetchSubmodules = true;
  };

  vendorHash = "sha256-MTwD9xkrq3EudppLSoONgcPCBWlbSmaODLH9NtYgVOk=";

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
