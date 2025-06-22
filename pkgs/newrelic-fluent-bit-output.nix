{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "newrelic-fluent-bit-output";
  version = "2.4.0";

  src = fetchFromGitHub {
    owner = "newrelic";
    repo = "newrelic-fluent-bit-output";
    rev = "v${version}";
    hash = "sha256-ODbAmC+O0LbO4CZJQRw8rzzMM1hC1dx8iB/y9mmEiNk=";
  };

  vendorHash = null;

  ldflags = [
    "-buildmode=c-shared"
  ];

  meta = {
    description = "A Fluent Bit output plugin that sends logs to New Relic";
    homepage = "https://github.com/newrelic/newrelic-fluent-bit-output";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ davsanchez ];
    platforms = lib.platforms.linux;
    # mainProgram = "newrelic-fluent-bit-output";
  };
}
