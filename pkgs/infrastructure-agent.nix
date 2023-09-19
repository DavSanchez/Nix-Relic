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
  version = "1.47.1";

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "infrastructure-agent";
    rev = version;
    hash = "sha256-+hgAMfMMbZQiqO8Sn+OtJDOCc6iZRWlQMH/q6EDGfXk=";
};

  vendorHash = "sha256-izjfwwKHR0tSuO+bjU5NT8r+uu8EhWl20GIfMjytNHk=";

  buildInputs = lib.optionals stdenv.isDarwin [
    # darwin.apple_sdk.frameworks.Cocoa
    darwin.apple_sdk.frameworks.Kernel
  ] ++ lib.optionals stdenv.isLinux [
    # xorg.libX11
    # xorg.libXcursor
    # xorg.libXi
    # xorg.libXinerama
    # xorg.libXrandr

    fluent-bit
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
