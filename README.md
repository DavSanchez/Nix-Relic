
[<img src="./nix-relic.png" alt="logo" width="200">](https://github.com/DavSanchez/Nix-Relic)

# Nix Relic

[![Build tests](https://github.com/DavSanchez/Nix-Relic/actions/workflows/build.yaml/badge.svg)](https://github.com/DavSanchez/Nix-Relic/actions/workflows/build.yaml)

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

This is a collection of some observability tools from New Relic packaged as Nix Flakes and accompanied by modules.

## Available packages

### New Relic Infrastructure Agent

```sh
nix shell .#infrastructure-agent

# or build the package and find the outputs in ./result
nix build .#infrastructure-agent
```

### OpenTelemetry Collector Builder (OCB)

```sh
nix shell .#ocb

# or build the package and find the outputs in ./result
nix build .#ocb
```

### New Relic Distribution for Open Telemetry Collector

```sh
nix shell .#nr-otel-collector

# or build the package and find the outputs in ./result
nix build .#nr-otel-collector
```

## Available modules

It might be possible that the modules defined here reference packages that are not yet present in `nixpkgs`. If you encounter this problem, add this flake's default overlay to your `nixpkgs.overlays` config. Assuming you have named this flake input as `nix-relic`:

```nix
{
  nixpkgs = {
    overlays = [
      inputs.nix-relic.overlays.default
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
