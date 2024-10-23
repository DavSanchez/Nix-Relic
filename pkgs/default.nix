# You can build the below packages using 'nix build .#example'
{ pkgs }:
{
  infrastructure-agent = pkgs.callPackage ./infrastructure-agent.nix { };
  nr-otel-collector = pkgs.callPackage ./nr-otel-collector.nix { };
}
