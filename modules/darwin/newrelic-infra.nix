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
    enable = mkEnableOption "newrelic-infra service";

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

    logFile = mkOption {
      type = types.path;
      default = "/var/log/newrelic-infra/newrelic-infra.log";
      description = mdDoc "Path to the log file";
    };

    errLogFile = lib.mkOption {
      type = types.path;
      default = "/var/log/newrelic-infra/newrelic-infra.stderr.log";
      description = mdDoc "Path to the error log file";
    };
  };

  config = mkIf cfg.enable {
    launchd.daemons.newrelic-infra =
      let
        conf =
          if cfg.configFile == null then
            settingsFormat.generate "config.yaml" cfg.settings
          else
            cfg.configFile;
      in
      {
        path = [ pkgs.infrastructure-agent ];

        serviceConfig = {
          ProgramArguments = [
            "${pkgs.infrastructure-agent}/bin/newrelic-infra-service"
            "-config"
            "${conf}"
          ];
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = cfg.errLogFile;
          StandardOutPath = cfg.logFile;
        };
      };
  };
}
