# Aggregates all flake checks.
{
  lib,
  pkgs,
  inputs,
}:
let
  # A pkgs set that also contains this flake's packages. We merge the plain
  # packages into `pkgs` instead of using `pkgs.extend` with the overlay, since
  # our package set no longer references stdenv at the top level (that would
  # cause infinite recursion when an overlay is applied).
  #
  # newrelic-fluent-bit-output is Linux-only, so it is filtered out elsewhere.
  ourPackages = import ../pkgs { pkgs = pkgs; };
  overlayPkgs =
    pkgs
    // (
      if pkgs.stdenv.hostPlatform.isLinux then
        ourPackages
      else
        builtins.removeAttrs ourPackages [ "newrelic-fluent-bit-output" ]
    );

  # Package set for the NixOS VM guests. The test driver runs on the host
  # (nixpkgs supports aarch64-darwin hosts driving aarch64-linux guests via
  # HVF), but the guest itself is always Linux, so the flake's packages must
  # be the Linux builds (`pkgs.pkgsLinux`).
  guestPkgs = pkgs.pkgsLinux // import ../pkgs { pkgs = pkgs.pkgsLinux; };
in
(import ./eval-tests.nix {
  inherit lib;
  pkgs = overlayPkgs;
  plainPkgs = pkgs;
})
// (import ./smoke-tests.nix {
  inherit lib;
  pkgs = overlayPkgs;
})
// (import ./vm-tests.nix {
  inherit lib;
  pkgs = overlayPkgs;
  inherit guestPkgs;
})
// {
  # Ensures every .nix file in the repo is formatted with the flake's formatter
  format-check =
    pkgs.runCommand "format-check"
      {
        files = builtins.filter (f: lib.hasSuffix ".nix" f) (lib.filesystem.listFilesRecursive ../.);
        formatter = "${pkgs.nixfmt}/bin/nixfmt";
      }
      ''
        for f in $files; do
              $formatter - <"$f" | cmp -s - "$f" || {
                echo "NOT FORMATTED: $f"
                echo "Run 'nix fmt' and commit the changes."
                exit 1
              }
            done
            touch $out
      '';
}
