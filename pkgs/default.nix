# You can build the below packages using 'nix build .#example'
#
# Note: newrelic-fluent-bit-output is Linux-only (it builds a C shared object
# for Fluent Bit). Platform filtering is done by the flake and the checks, not
# here, since referencing `stdenv` at the top level of an overlay-provided
# package set causes infinite recursion.
{ pkgs }:
let
  callPackage = pkgs.newScope pkgs;
in
{
  # nri-flex: standalone New Relic integration runner (e.g. S.M.A.R.T.)
  nri-flex = callPackage ./nri-flex.nix { };

  # Fluent Bit output plugin for New Relic, needed by the infra agent's log forwarding.
  newrelic-fluent-bit-output = callPackage ./newrelic-fluent-bit-output.nix { };

  # The New Relic distribution of the OpenTelemetry Collector (nrdot-collector)
  nrdot-collector = callPackage ./nrdot-collector.nix { };
}
