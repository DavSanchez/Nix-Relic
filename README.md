[<img src="./nix-relic.png" alt="logo" width="200">](https://github.com/DavSanchez/Nix-Relic)

# Nix Relic

[![Build tests](https://github.com/DavSanchez/Nix-Relic/actions/workflows/build.yaml/badge.svg)](https://github.com/DavSanchez/Nix-Relic/actions/workflows/build.yaml)

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

This is a collection of some infrastructure observability tools from New Relic packaged as Nix Flakes and accompanied by NixOS and nix-darwin modules.

## Usage as a flake

Add Nix-Relic to your `flake.nix`:

```nix
{
  inputs.nix-relic.url = "github:DavSanchez/Nix-Relic";
  # and, optionally
  # nix-relic.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nix-relic, nixpkgs }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # The modules reference packages that are not in nixpkgs, so the
        # overlay is required.
        { nixpkgs.overlays = [ nix-relic.overlays.additions ]; }
        nix-relic.nixosModules.newrelic-infra
      ];
    };
  };
}
```

### Adding the packages from `nix-relic`'s overlay

The NixOS modules reference packages that are not yet present in `nixpkgs`
(`nri-flex`, `newrelic-fluent-bit-output`, `nrdot-collector`). The
`infrastructure-agent` package itself is provided by nixpkgs.

Add this flake's default overlay to your `nixpkgs.overlays` config:

```nix
{
  nixpkgs.overlays = [ inputs.nix-relic.overlays.additions ];
}
```

## Available packages

### `infrastructure-agent`

Provided by nixpkgs as `pkgs.infrastructure-agent`. You can build it directly:

```sh
nix shell nixpkgs#infrastructure-agent
```

### `nri-flex`

A standalone integration runner (e.g. for S.M.A.R.T. monitoring):

```sh
nix shell github:DavSanchez/Nix-Relic#nri-flex
```

### `newrelic-fluent-bit-output` (Linux only)

The Fluent Bit output plugin (`out_newrelic.so`) required by the infra agent's
log forwarding:

```sh
nix shell github:DavSanchez/Nix-Relic#newrelic-fluent-bit-output
```

### `nrdot-collector`

The New Relic distribution of the OpenTelemetry Collector:

```sh
nix shell github:DavSanchez/Nix-Relic#nrdot-collector
```

## NixOS modules

### `services.newrelic-infra`

Starts the New Relic Infrastructure Agent as a `systemd` service.

```nix
{
  services.newrelic-infra = {
    enable = true;
    # Beware of including license keys in the file defined below!
    # The file will end up in plain text in the Nix Store.
    # Use encryption tools like `agenix` or `sops-nix` to handle this securely.
    configFile = ./newrelic-infra.yml;
  };
}
```

Instead of a file, you can declare the configuration in Nix:

```nix
{
  services.newrelic-infra = {
    enable = true;
    settings = {
      license_key = "your-ingest-license-key"; # better via agenix/sops-nix!
    };
  };
}
```

#### Config file example

The agent accepts a YAML configuration file. A minimal one looks like:

```yaml
# newrelic-infra.yml
license_key: your-ingest-license-key
log_level: info
```

For the full list of settings see the
[Infrastructure Agent configuration settings](https://docs.newrelic.com/docs/infrastructure/install-infrastructure-agent/configuration/infrastructure-agent-configuration-settings).

#### Log forwarding

The agent can forward logs using its built-in Fluent Bit integration:

```nix
{
  services.newrelic-infra = {
    enable = true;
    settings.license_key = "your-ingest-license-key"; # better via agenix/sops-nix!
    logging = [
      {
        name = "my-app";
        file = "/var/log/my-app.log";
        attributes = { service.name = "my-app"; };
      }
    ];
  };
}
```

See the
[Forward your logs using the infrastructure agent](https://docs.newrelic.com/docs/logs/forward-logs/forward-your-logs-using-infrastructure-agent/)
documentation for the available log source fields.

#### On-host integrations

You can run integrations such as `nri-flex` from the agent:

```nix
{
  services.newrelic-infra = {
    enable = true;
    settings.license_key = "your-ingest-license-key"; # better via agenix/sops-nix!
    integrations = [
      {
        name = "flex";
        package = pkgs.nri-flex;
        config = {
          integrations = [
            { name = "smart"; }
          ];
        };
      }
    ];
  };
}
```

#### Options

- `services.newrelic-infra.package` — the agent package (defaults to
  `pkgs.infrastructure-agent`).
- `services.newrelic-infra.settings` — the agent configuration as Nix.
- `services.newrelic-infra.configFile` — an explicit configuration file.
- `services.newrelic-infra.logging` — log sources to forward (see above).
- `services.newrelic-infra.fluentBitPackage` — the Fluent Bit New Relic output
  plugin package (defaults to `pkgs.newrelic-fluent-bit-output`).
- `services.newrelic-infra.integrations` — on-host integrations to run.

### `services.nrdot-collector`

Starts the New Relic distribution of the OpenTelemetry Collector:

```nix
{
  services.nrdot-collector = {
    enable = true;
    settings = {
      extensions.health_check = {};
      receivers.otlp.protocols.grpc.endpoint = "localhost:4317";
      exporters.debug.verbosity = "basic";
      service.extensions = [ "health_check" ];
      service.pipelines.traces = {
        receivers = [ "otlp" ];
        exporters = [ "debug" ];
      };
    };
  };
}
```

## Darwin (macOS)

### `services.newrelic-infra` — `launchd` daemon

```nix
{
  services.newrelic-infra = {
    enable = true;
    configFile = ./newrelic-infra.yml; # use agenix/sops-nix for secrets!
    logFile = ./path/to/file.log;
    errLogFile = ./path/to/errfile.log;
  };
}
```

### `services.nrdot-collector` — `launchd` daemon

```nix
{
  services.nrdot-collector = {
    enable = true;
    configFile = ./nrdot-collector.yml;
    logFile = ./path/to/file.log;
    errLogFile = ./path/to/errfile.log;
  };
}
```

## Security

Beware of including license keys in the files defined in the configs, such as
the one passed to `services.newrelic-infra.configFile` or `settings`. These
files end up in plain text in the Nix Store.

Use Nix secret management utilities like
[`agenix`](https://github.com/ryantm/agenix) or
[`sops-nix`](https://github.com/Mic92/sops-nix) to handle this securely.

## Development

Run the full test suite (unit/eval tests, package smoke tests, and NixOS VM
integration tests on Linux):

```sh
nix flake check
```

Format the Nix code:

```sh
nix fmt
```

Open a dev shell with formatting and linting tools:

```sh
nix develop
```