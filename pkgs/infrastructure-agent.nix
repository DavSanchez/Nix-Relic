{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "infrastructure-agent";
  version = "1.48.2";

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "infrastructure-agent";
    rev = version;
    hash = "sha256-3kr3j5FjCvEd3IJn2UK+bncx69+2AgEqHU1qHz+C680=";
  };

  vendorHash = "sha256-dEjZ6qtJOg+3QhjNQOL/3Gyi1yF6LGfDczWgjwTedhc=";

  ldflags = [
    "-s"
    "-w"
    "-X main.buildVersion=${version}"
    "-X main.gitCommit=${src.rev}"
  ];

  CGO_ENABLED =
    if stdenv.isDarwin
    then "1"
    else "0";

  subPackages = [
    "cmd/newrelic-infra"
    "cmd/newrelic-infra-ctl"
    "cmd/newrelic-infra-service"
  ];

  meta = with lib; {
    description = "New Relic Infrastructure Agent";
    homepage = "https://github.com/newrelic/infrastructure-agent.git";
    license = licenses.asl20;
    maintainers = with maintainers; [ DavSanchez ];
    mainProgram = "newrelic-infra";
  };
}
