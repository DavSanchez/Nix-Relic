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
    getExe
    ;
  cfg = config.services.nrdot-collector;
  settingsFormat = pkgs.formats.yaml { };
in
{
  options.services.nrdot-collector = {
    enable = mkEnableOption "New Relic Distribution for OpenTelemetry Collector service";

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.nrdot-collector or null;
      description = ''
        The New Relic distribution of the OpenTelemetry Collector package.
        Defaults to the `nrdot-collector` package from this flake's overlay.
      '';
    };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
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
      default = "/var/log/nrdot-collector/nrdot-collector.log";
      description = mdDoc "Path to the log file";
    };

    errLogFile = mkOption {
      type = types.path;
      default = "/var/log/nrdot-collector/nrdot-collector.stderr.log";
      description = mdDoc "Path to the error log file";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.package != null;
        message = ''
          services.nrdot-collector requires the nrdot-collector package, but it
          is not available. Add this flake's overlay to nixpkgs.overlays so that
          pkgs.nrdot-collector exists.
        '';
      }
    ];

    launchd.daemons.nrdot-collector =
      let
        conf =
          if cfg.configFile == null then
            settingsFormat.generate "config.yaml" cfg.settings
          else
            cfg.configFile;
      in
      {
        serviceConfig = {
          ProgramArguments = [
            "${getExe cfg.package}"
            "--config=file:${conf}"
          ];
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = cfg.errLogFile;
          StandardOutPath = cfg.logFile;
        };
      };
  };
}
