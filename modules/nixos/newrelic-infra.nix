{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    mdDoc
    mkPackageOption
    mkMerge
    ;
  inherit (lib.types)
    nullOr
    listOf
    str
    package
    attrsOf
    submodule
    ;

  cfg = config.services.newrelic-infra;
  settingsFormat = pkgs.formats.yaml { };

  integrationModule = { name, ... }: {
    options = {
      name = mkOption {
        type = str;
        description = mdDoc "Name of the integration instance.";
      };
      package = mkOption {
        type = package;
        description = mdDoc ''
          Package providing the integration executable.
        '';
      };
      interval = mkOption {
        type = str;
        default = "15s";
        description = mdDoc "How often the integration should run.";
      };
      cliArgs = mkOption {
        type = listOf str;
        default = [ ];
        description = mdDoc "Extra CLI arguments passed to the integration executable.";
      };
      env = mkOption {
        type = attrsOf str;
        default = { };
        description = mdDoc "Environment variables for the integration process.";
      };
      config = mkOption {
        type = settingsFormat.type;
        default = { };
        description = mdDoc "Embedded configuration for the integration.";
      };
    };
  };
in
{
  options.services.newrelic-infra = {
    enable = mkEnableOption "New Relic Infrastructure Agent service";

    package = mkPackageOption pkgs "infrastructure-agent" { };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      description = mdDoc ''
        Specify the configuration for the Infra Agent in Nix.

        See <https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/configuration/infrastructure-agent-configuration-settings> for available options.
      '';
    };
    configFile = mkOption {
      type = nullOr types.path;
      default = null;
      description = mdDoc ''
        Specify a path to a configuration file that the Infrastructure Agent should use.

        If set, `settings` is ignored.
      '';
    };

    logging = mkOption {
      type = listOf settingsFormat.type;
      default = [ ];
      description = mdDoc ''
        Log sources to forward to New Relic using the agent's built-in log
        forwarding (Fluent Bit). Each entry follows the format of the agent's
        `logging.d` configuration files:

        ```nix
        logging = [{
          name = "systemd";
          systemd = "my-service.service";
        }];
        ```

        See <https://docs.newrelic.com/docs/logs/forward-logs/forward-your-logs-using-infrastructure-agent/> for the available fields.
      '';
    };

    fluentBitPackage = mkOption {
      type = nullOr package;
      default = pkgs.newrelic-fluent-bit-output or null;
      description = mdDoc ''
        Package providing the Fluent Bit New Relic output plugin
        (`out_newrelic.so`), required for log forwarding.

        Defaults to the `newrelic-fluent-bit-output` package from this flake's
        overlay, or `null` if the overlay is not applied.
      '';
    };

    integrations = mkOption {
      type = listOf (submodule integrationModule);
      default = [ ];
      description = mdDoc ''
        On-host integrations for the agent to run, e.g. `nri-flex`. Each entry
        is written to an `integrations.d` configuration file.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      systemd.services.newrelic-infra = {
        description = "New Relic Infrastructure Agent";

        after = [
          "dbus.service"
          "syslog.target"
          "network.target"
        ];

        # Ensure the agent and its integrations can find system binaries
        path =
          with pkgs;
          [
            cfg.package
            kmod
            systemd
            util-linux
            coreutils
            gawk
            gnused
          ]
          ++ (map (integration: integration.package) cfg.integrations);

        serviceConfig =
          let
            conf =
              if cfg.configFile == null then
                settingsFormat.generate "config.yaml" cfg.settings
              else
                cfg.configFile;
          in
          {
            RuntimeDirectory = "newrelic-infra";
            Type = "simple";
            ExecStart = "${cfg.package}/bin/newrelic-infra-service -config ${conf}";
            MemoryMax = "1G";
            Restart = "always";
            RestartSec = 20;
            PIDFile = "/run/newrelic-infra/newrelic-infra.pid";
            # The agent invokes FHS absolute paths such as /sbin/lsmod,
            # /sbin/modinfo and /sbin/udevadm that do not exist on NixOS.
            # Bind the NixOS system path over the expected FHS locations.
            # See https://github.com/DavSanchez/Nix-Relic/issues/88
            BindReadOnlyPaths = [
              "/run/current-system/sw/bin:/sbin"
              "/run/current-system/sw/bin/systemctl:/bin/systemctl"
            ];
          };

        unitConfig = {
          StartLimitInterval = 0;
          StartLimitBurst = 5;
        };

        wantedBy = [ "multi-user.target" ];
      };
    }
    (mkIf (cfg.logging != [ ]) {
      # Wire the agent's built-in log forwarding (Fluent Bit supervisor)
      services.newrelic-infra.settings.fluent_bit_exe_path = "${pkgs.fluent-bit}/bin/fluent-bit";
      services.newrelic-infra.settings.fluent_bit_parsers_path = "${pkgs.fluent-bit}/etc/fluent-bit/parsers.conf";

      # The New Relic output plugin is optional: without the overlay there is no
      # package to provide out_newrelic.so.
      services.newrelic-infra.settings.fluent_bit_nr_lib_path = mkIf (
        cfg.fluentBitPackage != null
      ) "${cfg.fluentBitPackage}/lib/out_newrelic.so";

      environment.etc."newrelic-infra/logging.d/logging.yml" = {
        source = settingsFormat.generate "logging.yml" { logs = cfg.logging; };
        mode = "0400";
      };
    })
    (mkIf (cfg.integrations != [ ]) {
      environment.etc = builtins.listToAttrs (
        map (integration: {
          name = "newrelic-infra/integrations.d/${integration.name}.yml";
          value = {
            source = settingsFormat.generate "${integration.name}.yml" {
              integrations = [
                {
                  name = integration.name;
                  exec = "${integration.package}/bin/${integration.package.meta.mainProgram or integration.name}";
                  interval = integration.interval;
                  cli_args = integration.cliArgs;
                  inherit (integration) env;
                  inherit (integration) config;
                }
              ];
            };
            mode = "0400";
          };
        }) cfg.integrations
      );
    })
  ]);
}
