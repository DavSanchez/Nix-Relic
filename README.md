
[<img src="./nix-relic.png" alt="logo" width="200">](https://github.com/DavSanchez/Nix-Relic)

# Nix Relic

[![Build tests](https://github.com/DavSanchez/Nix-Relic/actions/workflows/build.yaml/badge.svg)](https://github.com/DavSanchez/Nix-Relic/actions/workflows/build.yaml)

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

This is a collection of some infrastructure observability tools from New Relic packaged as Nix Flakes and accompanied by NixOS and nix-darwin modules.

## Available packages

### New Relic Infrastructure Agent

```sh
# Make it available in your shell
nix shell github:DavSanchez/Nix-Relic#infrastructure-agent

# or build the package and find the outputs in ./result
nix build github:DavSanchez/Nix-Relic#infrastructure-agent
```

### OpenTelemetry Collector Builder (OCB)

```sh
# Make it available in your shell
nix shell github:DavSanchez/Nix-Relic#ocb

# or build the package and find the outputs in ./result
nix build github:DavSanchez/Nix-Relic#ocb
```

### New Relic Distribution for OpenTelemetry Collector

```sh
# Make it available in your shell
nix shell github:DavSanchez/Nix-Relic#nr-otel-collector

# or build the package and find the outputs in ./result
nix build github:DavSanchez/Nix-Relic#nr-otel-collector
```

## Available modules

It might be possible that the modules defined here reference packages that are not yet present in `nixpkgs`. If you encounter this problem, add this flake's default overlay to your `nixpkgs.overlays` config. Assuming you have named this flake input as `nix-relic`:

```nix
{
  nixpkgs = {
    overlays = [
      inputs.nix-relic.overlays.additions
    ];
  };
}
```

### NixOS

#### Infrastructure agent `systemd` service

```nix
{
  services.newrelic-infra = {
    enable = true;
    configFile = ./newrelic-infra.yml;
  };
}
```

#### Use the New Relic Distribution for OpenTelemetry Collector

A module for setting up an OpenTelemetry collector is already provided by NixOS, we only need to change it so it uses our New Relic Distribution package:

```nix
{
  services.opentelemetry-collector = {
    enable = true;
    package = pkgs.nr-otel-collector; # Here!
    configFile = ./nr-otel-collector.yaml;
  };
}
```

### Darwin (macOS)

#### Infrastructure agent `launchd` daemon

```nix
{
  services.newrelic-infra = {
    enable = true;
    configFile = ./newrelic-infra.yml; 
    logFile = ./path/to/file.log;
    errLogFile = ./path/to/errfile.log;
  };
}
```


#### New Relic Distribution for OpenTelemetry Collector `launchd` daemon

```nix
{
  services.nr-otel-collector = {
    enable = true;
    configFile = ./nr-otel-collector.yml; 
    logFile = ./path/to/file.log;
    errLogFile = ./path/to/errfile.log;
  };
}
```
