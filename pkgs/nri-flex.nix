{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "nri-flex";
  version = "1.18.10";

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "nri-flex";
    rev = "v${version}";
    hash = "sha256-S3v/dky0iI5JfhWu7yPVCVm9s1x6lMS+Qg/9/oVqlKc=";
  };

  subPackages = [ "cmd/nri-flex" ];

  vendorHash = "sha256-4qo9zyn9VTg7oh5PtDyddnbMbQg40d2ql1Crmklv+fc=";

  ldflags = [
    "-s"
    "-w"
    # "-X github.com/newrelic/nri-flex/internal/load.IntegrationVersion=${version}" # tests do not expect this so not using it for now
  ];

  meta = {
    description = "An application-agnostic, all-in-one New Relic integration";
    homepage = "https://github.com/newrelic/nri-flex";
    changelog = "https://github.com/newrelic/nri-flex/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ davsanchez ];
    mainProgram = "nri-flex";
  };
}
