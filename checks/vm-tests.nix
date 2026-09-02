# NixOS VM tests. The driver always runs on the host; nixpkgs supports
# aarch64-darwin hosts running aarch64-linux guests via HVF.
#
# Note: packages from this flake are injected explicitly through the modules'
# `package` options rather than via `nixpkgs.overlays`, because the NixOS test
# framework sets `nixpkgs.pkgs` and makes the `nixpkgs` configuration read-only.
{
  lib,
  pkgs,
  guestPkgs,
}:
let
  # Outer pkgs (this flake's host package set), used for `testers.runNixOSTest`.
  # The node definitions below shadow `pkgs` with the NixOS test framework's
  # own package set, so the flake's packages injected into the guests must be
  # the Linux builds (`guestPkgs`).
  flakePkgs = pkgs;

  # nixpkgs pins gic-version=2 for aarch64-darwin hosts in qemu-common.nix,
  # but qemu's HVF accelerator on Apple Silicon only supports GICv3, so guests
  # never boot on darwin hosts without overriding the machine type.
  # See https://github.com/NixOS/nixpkgs/issues/380524
  darwinQemuMachineOverride = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin [
    "-machine"
    "virt,gic-version=3,accel=hvf"
  ];

  infraModule = import ../modules/nixos/newrelic-infra.nix;
  nrdotModule = import ../modules/nixos/nrdot-collector.nix;
in
{
  # Boots a VM with the infra agent running and verifies the service comes up,
  # the log-forwarding config is generated, and that the #88 fix (FHS /sbin
  # paths bound into the service namespace) is in effect.
  vm-newrelic-infra = flakePkgs.testers.runNixOSTest {
    name = "newrelic-infra";
    nodes.machine =
      {
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ infraModule ];

        services.newrelic-infra = {
          enable = true;
          package = guestPkgs.infrastructure-agent;
          fluentBitPackage = guestPkgs.newrelic-fluent-bit-output;
          settings.license_key = "test";
          logging = [
            {
              name = "test-log";
              file = "/var/log/test.log";
            }
          ];
        };

        virtualisation.qemu.options = darwinQemuMachineOverride;

        environment.systemPackages = [
          pkgs.curl
          pkgs.util-linux
        ];
      };

    testScript = ''
      start_all()
      machine.wait_for_unit("newrelic-infra.service")
      machine.succeed("systemctl is-active newrelic-infra.service")

      # Regression test for #88: /sbin must be bound into the service's
      # mount namespace so the agent can invoke /sbin/lsmod and friends.
      # systemd resolves the /run/current-system/sw symlink, so the bind shows
      # up as a dedicated /sbin mount (from the store's system-path).
      pid = machine.succeed("systemctl show -p MainPID --value newrelic-infra.service").strip()
      machine.succeed(f"grep -q ' /sbin ' /proc/{pid}/mountinfo")
      machine.succeed(f"nsenter -t {pid} -m test -x /sbin/lsmod")

      # The log-forwarding config is written to logging.d
      machine.succeed("test -f /etc/newrelic-infra/logging.d/logging.yml")
      machine.succeed("grep -q 'test-log' /etc/newrelic-infra/logging.d/logging.yml")
    '';
  };

  # Boots a VM with the nrdot-collector running and verifies the service starts
  # and its health check endpoint responds.
  vm-nrdot-collector = flakePkgs.testers.runNixOSTest {
    name = "nrdot-collector";
    nodes.machine =
      {
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ nrdotModule ];

        services.nrdot-collector = {
          enable = true;
          package = guestPkgs.nrdot-collector;
          settings = {
            receivers.otlp.protocols.grpc.endpoint = "localhost:4317";
            receivers.otlp.protocols.http.endpoint = "localhost:4318";
            exporters.debug.verbosity = "basic";
            extensions.health_check = { };
            service.extensions = [ "health_check" ];
            service.pipelines.traces = {
              receivers = [ "otlp" ];
              exporters = [ "debug" ];
            };
          };
        };

        virtualisation.qemu.options = darwinQemuMachineOverride;

        environment.systemPackages = [ pkgs.curl ];
      };

    testScript = ''
      start_all()
      machine.wait_for_unit("nrdot-collector.service")
      machine.succeed("systemctl is-active nrdot-collector.service")
      machine.wait_until_succeeds("curl -sf http://localhost:13133/")
    '';
  };
}
