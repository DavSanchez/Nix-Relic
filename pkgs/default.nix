# You can build the below packages using 'nix build .#example'
{pkgs}: rec {
  infrastructure-agent = pkgs.callPackage ./infrastructure-agent.nix {};
  newrelic-fluent-bit-output = pkgs.callPackage ./newrelic-fluent-bit-output.nix {};
  
  ocb = pkgs.callPackage ./ocb.nix {};

  nr-otel-collector = pkgs.callPackage ./nr-otel-collector {
    # nr-otel-collector needs a specific version of ocb at this moment, hence this hack
    ocb = let
      version = "0.86.0";
      src = pkgs.fetchFromGitHub {
        owner = "open-telemetry";
        repo = "opentelemetry-collector";
        rev = "cmd/builder/v${version}";
        hash = "sha256-Ucp00OjyPtHA6so/NOzTLtPSuhXwz6A2708w2WIZb/E=";
        fetchSubmodules = true;
      };
    in
      # For why this was needed, see
      # https://discourse.nixos.org/t/inconsistent-vendoring-in-buildgomodule-when-overriding-source/9225/6
      ocb.override rec {
        buildGoModule = args:
          pkgs.buildGoModule (args
            // {
              inherit src version;
              vendorHash = "sha256-MTwD9xkrq3EudppLSoONgcPCBWlbSmaODLH9NtYgVOk=";
            });
      };
  };
}
