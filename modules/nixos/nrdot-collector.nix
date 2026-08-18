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
    getExe
    isStorePath
    literalMD
    ;

  cfg = config.services.nrdot-collector;
  collector = cfg.package;

  settingsFormat = pkgs.formats.yaml { };
  generatedConf =
    if cfg.configFile == null then
      settingsFormat.generate "config.yaml" cfg.settings
    else
      cfg.configFile;
  conf =
    if cfg.validateConfigFile then
      pkgs.runCommandLocal "config.yaml"
        {
          inherit generatedConf;
        }
        ''
          cp $generatedConf $out
          ${getExe collector} validate --config=file:$out
        ''
    else
      generatedConf;
in
{
  options.services.nrdot-collector = {
    enable = mkEnableOption "New Relic Distribution for OpenTelemetry Collector";

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
      description = ''
        Specify the configuration for the OpenTelemetry Collector in Nix.

        See <https://opentelemetry.io/docs/collector/configuration/> for available options.
      '';
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Specify a path to a configuration file that the OpenTelemetry Collector should use.
      '';
    };

    validateConfigFile =
      lib.mkEnableOption "Validate the generated configuration file at build time"
      // {
        defaultText = literalMD "`true` if `configFile` is a store path";
        default = isStorePath cfg.configFile;
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
      {
        assertion = (cfg.settings == { }) != (cfg.configFile == null);
        message = ''
          Please specify a configuration for nrdot-collector with either
          'services.nrdot-collector.settings' or
          'services.nrdot-collector.configFile'.
        '';
      }
    ];

    systemd.services.nrdot-collector = {
      description = "New Relic Distribution for OpenTelemetry Collector";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${getExe collector} --config=file:${conf}";
        DynamicUser = true;
        Restart = "always";
        ProtectSystem = "full";
        DevicePolicy = "closed";
        NoNewPrivileges = true;
        WorkingDirectory = "%S/nrdot-collector";
        StateDirectory = "nrdot-collector";
      };
    };
  };
}
