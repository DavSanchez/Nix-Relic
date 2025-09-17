{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "nri-flex";
  version = "1.16.5";

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "nri-flex";
    rev = "v${version}";
    hash = "sha256-VDQTQ/eOip+9UC6WxwNJZqKfhk0wWm157fIWSDtO4l4=";
  };

  subPackages = "cmd/nri-flex";

  vendorHash = "sha256-mG/PI6sC4CLahqaU6oJe6rb+WsPNApAEyEMnilw/e4A=";

  ldflags = [
    "-s"
    "-w"
    # "-X github.com/newrelic/nri-flex/internal/load.IntegrationVersion=${version}" # tests do not expect this so not using it for now
  ];

  meta = {
    description = "An application-agnostic, all-in-one New Relic integration integration";
    homepage = "https://github.com/newrelic/nri-flex";
    changelog = "https://github.com/newrelic/nri-flex/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ davsanchez ];
    mainProgram = "nri-flex";
  };
}
