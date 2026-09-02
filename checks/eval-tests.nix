# Unit tests that evaluate the modules and assert on the resulting config.
# These run quickly and don't build any packages.
{
  lib,
  pkgs,
  plainPkgs,
}:
let
  inherit (lib) types mkOption runTests;

  # Minimal stub options so the NixOS modules can be evaluated standalone
  moduleStubs = {
    options = {
      environment.etc = mkOption {
        type = types.attrsOf types.anything;
        default = { };
      };
      systemd.services = mkOption {
        type = types.attrsOf types.anything;
        default = { };
      };
      launchd.daemons = mkOption {
        type = types.attrsOf types.anything;
        default = { };
      };
      assertions = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              assertion = mkOption {
                type = types.bool;
              };
              message = mkOption {
                type = types.str;
              };
            };
          }
        );
        default = [ ];
      };
    };
  };

  mkEval =
    {
      module,
      pkg ? plainPkgs,
      config,
    }:
    lib.evalModules {
      modules = [
        moduleStubs
        module
        config
      ];
      specialArgs = {
        pkgs = pkg;
      };
    };

  infraModule = import ../modules/nixos/newrelic-infra.nix;
  nrdotModule = import ../modules/nixos/nrdot-collector.nix;

  infraWith =
    {
      pkg ? plainPkgs,
      config ? { },
    }:
    (mkEval {
      module = infraModule;
      inherit pkg;
      config = {
        services.newrelic-infra = {
          enable = true;
        }
        // config;
      };
    }).config.services.newrelic-infra;

  infraConfigWith =
    {
      pkg ? plainPkgs,
      config ? { },
    }:
    (mkEval {
      module = infraModule;
      inherit pkg;
      config = {
        services.newrelic-infra = {
          enable = true;
        }
        // config;
      };
    }).config;

  # Only meaningful on Linux: the fluent-bit output plugin is Linux-only
  linuxOnlyTests = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    testNixosInfraLoggingNrLibWithOverlay = {
      expr =
        (infraWith {
          pkg = pkgs;
          config = {
            logging = [
              {
                name = "test";
                file = "/var/log/test.log";
              }
            ];
          };
        }).settings.fluent_bit_nr_lib_path;
      expected = "${pkgs.newrelic-fluent-bit-output}/lib/out_newrelic.so";
    };

    # The service runs with system utilities (kmod is Linux-only) on its PATH
    testNixosInfraPathIncludesKmod = {
      expr = lib.elem pkgs.kmod (infraConfigWith { }).systemd.services.newrelic-infra.path;
      expected = true;
    };
  };

  tests = {
    # The service is defined and uses the agent's service binary
    testNixosInfraService = {
      expr = (infraConfigWith { }).systemd.services.newrelic-infra.serviceConfig.ExecStart;
      expected = "${pkgs.infrastructure-agent}/bin/newrelic-infra-service -config ${
        (pkgs.formats.yaml { }).generate "config.yaml" (infraWith { }).settings
      }";
    };

    # Regression test for https://github.com/DavSanchez/Nix-Relic/issues/88:
    # the agent hardcodes FHS paths like /sbin/lsmod
    testNixosInfraLsmodBindPaths = {
      expr = (infraConfigWith { }).systemd.services.newrelic-infra.serviceConfig.BindReadOnlyPaths;
      expected = [
        "/run/current-system/sw/bin:/sbin"
        "/run/current-system/sw/bin/systemctl:/bin/systemctl"
      ];
    };

    # The package option defaults to nixpkgs' infrastructure-agent
    testNixosInfraPackageDefault = {
      expr = (infraWith { }).package;
      expected = pkgs.infrastructure-agent;
    };

    # Log forwarding wires the fluent-bit executable into the agent settings
    testNixosInfraLoggingFluentBitPath = {
      expr =
        (infraWith {
          config = {
            logging = [
              {
                name = "test";
                file = "/var/log/test.log";
              }
            ];
          };
        }).settings.fluent_bit_exe_path;
      expected = "${pkgs.fluent-bit}/bin/fluent-bit";
    };

    # Without the overlay there is no output plugin package
    testNixosInfraLoggingNrLibWithoutOverlay = {
      expr =
        (infraWith {
          config = {
            logging = [
              {
                name = "test";
                file = "/var/log/test.log";
              }
            ];
          };
        }).fluentBitPackage;
      expected = null;
    };

    # The logging config file is dropped into logging.d
    testNixosInfraLoggingFileGenerated = {
      expr =
        (infraConfigWith {
          config = {
            logging = [
              {
                name = "test";
                file = "/var/log/test.log";
              }
            ];
          };
        }).environment.etc ? "newrelic-infra/logging.d/logging.yml";
      expected = true;
    };

    # No logging config file is generated when logging is disabled
    testNixosInfraNoLoggingFileWithoutLogs = {
      expr = (infraConfigWith { }).environment.etc ? "newrelic-infra/logging.d/logging.yml";
      expected = false;
    };

    # Integrations are written to integrations.d
    testNixosInfraIntegrationsFileGenerated = {
      expr =
        (infraConfigWith {
          config = {
            integrations = [
              {
                name = "flex";
                package = pkgs.nri-flex;
              }
            ];
          };
        }).environment.etc ? "newrelic-infra/integrations.d/flex.yml";
      expected = true;
    };

    # The nrdot-collector package is only available through the overlay
    testNixosNrdotCollectorPackageFromOverlay = {
      expr =
        (mkEval {
          module = nrdotModule;
          pkg = pkgs;
          config = {
            services.nrdot-collector = {
              enable = true;
              settings = { };
            };
          };
        }).config.services.nrdot-collector.package;
      expected = pkgs.nrdot-collector;
    };

    # The nrdot-collector service is defined with the expected binary
    testNixosNrdotCollectorService = {
      expr =
        (mkEval {
          module = nrdotModule;
          pkg = pkgs;
          config = {
            services.nrdot-collector = {
              enable = true;
              settings = { };
            };
          };
        }).config.systemd.services.nrdot-collector.serviceConfig.ExecStart;
      expected = "${pkgs.nrdot-collector}/bin/nrdot-collector --config=file:${
        (pkgs.formats.yaml { }).generate "config.yaml" { }
      }";
    };
  };

  failures = runTests (tests // linuxOnlyTests);
in
{
  eval-tests = pkgs.runCommand "eval-tests" { } (
    ''
      ${lib.concatMapStringsSep "\n" (failure: ''
        echo "FAIL: ${failure.name}"
        echo "  expected: ${lib.generators.toPretty { } failure.expected}"
        echo "  result:   ${lib.generators.toPretty { } failure.result}"
      '') failures}
    ''
    + (if failures == [ ] then "touch $out" else "exit 1")
  );
}
