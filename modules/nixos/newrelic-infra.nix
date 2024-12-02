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
    ;

  cfg = config.services.newrelic-infra;
  settingsFormat = pkgs.formats.yaml { };
in
{
  options.services.newrelic-infra = {
    enable = lib.mkEnableOption "newrelic-infra service";
    # TODO: withIntegrations = [ drv drv ... ];

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      description = mdDoc ''
        Specify the configuration for the Infra Agent in Nix.

        See <https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/configuration/infrastructure-agent-configuration-settings> for available options.
      '';
    };
    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = mdDoc ''
        Specify a path to a configuration file that the Infrastructure Agent should use.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.newrelic-infra = {
      description = "New Relic Infrastructure Agent";

      after = [
        "dbus.service"
        "syslog.target"
        "network.target"
      ];

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
          ExecStart = "${pkgs.infrastructure-agent}/bin/newrelic-infra-service -config ${conf}";
          MemoryMax = "1G";
          Restart = "always";
          RestartSec = 20;
          PIDFile = "/run/newrelic-infra/newrelic-infra.pid";
        };

      unitConfig = {
        StartLimitInterval = 0;
        StartLimitBurst = 5;
      };

      wantedBy = [ "multi-user.target" ];
    };
  };
}
