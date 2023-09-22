{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types getExe;
  cfg = config.services.newrelic-infra;
  settingsFormat = pkgs.formats.yaml {};
in {
  options.services.nr-otel-collector = {
    enable = mkEnableOption "New Relic distribution for OpenTelemetry Collector service";

    settings = mkOption {
      type = settingsFormat.type;
      default = {};
      description = ''
        Specify the configuration for Opentelemetry Collector in Nix.

        See <https://opentelemetry.io/docs/collector/configuration> for available options.
      '';
    };
    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Specify a path to a configuration file that Opentelemetry Collector should use.
      '';
    };

    logFile = mkOption {
      type = types.path;
      default = "/var/log/nr-otel-collector/nr-otel-collector.log";
      description = "Path to the log file";
    };

    errLogFile = lib.mkOption {
      type = types.path;
      default = "/var/log/nr-otel-collector/nr-otel-collector.stderr.log";
      description = "Path to the error log file";
    };
  };

  config = mkIf cfg.enable {
    launchd.daemons.newrelic-infra = let
      conf =
        if cfg.configFile == null
        then settingsFormat.generate "config.yaml" cfg.settings
        else cfg.configFile;
    in {
      command = "${getExe pkgs.nr-otel-collector} --config=file:${conf}";

      serviceConfig = {
        StandardErrorPath = cfg.errLogFile;
        StandardOutPath = cfg.logFile;
      };
    };
  };
}
