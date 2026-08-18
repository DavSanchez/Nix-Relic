# You can build the below packages using 'nix build .#example'
{ pkgs }:
let
  callPackage = pkgs.newScope pkgs;
in
{
  # The New Relic distribution of the OpenTelemetry Collector (nrdot-collector)
  nrdot-collector = callPackage ./nrdot-collector.nix { };
}