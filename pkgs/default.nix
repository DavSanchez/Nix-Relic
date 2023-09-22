# You can build the below packages using 'nix build .#example'
{pkgs}: rec {
  infrastructure-agent = pkgs.callPackage ./infrastructure-agent.nix {};
  ocb = pkgs.callPackage ./ocb.nix {};
  nr-otel-collector = pkgs.callPackage ./nr-otel-collector.nix { inherit ocb; };
}
