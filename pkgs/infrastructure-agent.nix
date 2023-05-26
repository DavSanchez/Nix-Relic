{
  lib,
  buildGoModule,
  fetchFromGitHub,
  stdenv,
  IOKit,
  CoreFoundation,
  Security,
}:
buildGoModule rec {
  pname = "infrastructure-agent";
  version = "1.42.1";

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "infrastructure-agent";
    rev = version;
    hash = "sha256-TlgHfe5Gn1L9hULLFfR2RUZTHrw6i2qi9hV/tzYiuhI=";
  };

  vendorHash = "sha256-BtaLSLuwICD6kRaQgMdVIptiRKlex8p3bOlpu9fZno0=";

  buildInputs = lib.optionals stdenv.isDarwin [
    IOKit
    CoreFoundation
    Security
  ];

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
    homepage = "https://github.com/newrelic/infrastructure-agent";
    license = licenses.asl20;
    maintainers = with maintainers; [DavSanchez];
  };
}
