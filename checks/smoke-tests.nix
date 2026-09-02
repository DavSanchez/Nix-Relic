# Smoke tests that build each package and verify the binary behaves.
{
  lib,
  pkgs,
}:
let
  runTest =
    name: text:
    pkgs.testers.runCommand {
      inherit name;
      script = ''
        echo "Running smoke test: ${name}"
        bash -e <<'EOF'
        ${text}
        EOF
        touch $out
      '';
    };

  nri-flex = pkgs.nri-flex;
  nrdot-collector = pkgs.nrdot-collector;
  plugin = pkgs.newrelic-fluent-bit-output or null;

  version = "2.0.0";
  configFile = pkgs.writeText "config.yaml" ''
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: localhost:4317
          http:
            endpoint: localhost:4318
    exporters:
      debug:
        verbosity: basic
    extensions:
      health_check:
    service:
      extensions: [health_check]
      pipelines:
        traces:
          receivers: [otlp]
          exporters: [debug]
  '';
  smokeNrdot = runTest "smoke-nrdot-collector" ''
    ${lib.getExe nrdot-collector} --version | grep -q "${version}"
    ${lib.getExe nrdot-collector} validate --config=file:${configFile}
  '';
in
{
  smoke-nrdot-collector = smokeNrdot;
  smoke-nri-flex = runTest "smoke-nri-flex" ''
    ${lib.getExe nri-flex} -h >/dev/null 2>&1
  '';
}
// lib.optionalAttrs (plugin != null) {
  smoke-newrelic-fluent-bit-output = runTest "smoke-newrelic-fluent-bit-output" ''
    test -f "${plugin}/lib/out_newrelic.so"
    file "${plugin}/lib/out_newrelic.so" | grep -q "shared object"
  '';
}
