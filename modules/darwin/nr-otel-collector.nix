{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types mdDoc getExe;
  cfg = config.services.nr-otel-collector;
  settingsFormat = pkgs.formats.yaml {};
in {
  options.services.nr-otel-collector = {
    enable = mkEnableOption "New Relic distribution for OpenTelemetry Collector service";

    settings = mkOption {
      type = settingsFormat.type;
      default = {};
      description = mdDoc ''
        Specify the configuration for Opentelemetry Collector in Nix.

        See <https://opentelemetry.io/docs/collector/configuration> for available options.
      '';
    };
    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = mdDoc ''
        Specify a path to a configuration file that Opentelemetry Collector should use.
      '';
    };

    logFile = mkOption {
      type = types.path;
      default = "/var/log/nr-otel-collector/nr-otel-collector.log";
      description = mdDoc "Path to the log file";
    };

    errLogFile = mkOption {
      type = types.path;
      default = "/var/log/nr-otel-collector/nr-otel-collector.stderr.log";
      description = mdDoc "Path to the error log file";
    };
  };

  config = mkIf cfg.enable {
    launchd.daemons.nr-otel-collector = let
      conf =
        if cfg.configFile == null
        then settingsFormat.generate "config.yaml" cfg.settings
        else cfg.configFile;
    in {
      path = [ pkgs.nr-otel-collector ];

      serviceConfig = {
        ProgramArguments = [ "${getExe pkgs.nr-otel-collector}" "--config=file:${conf}" ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardErrorPath = cfg.errLogFile;
        StandardOutPath = cfg.logFile;
      };
    };
  };
}
