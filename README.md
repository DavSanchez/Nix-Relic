# NixObs

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

This is a collection of some observability tools packaged for Nix and accompanied by modules.

## Available packages

### New Relic Infrastructure Agent

```sh
nix shell .#infrastructure-agent

# or build the package and find the outputs in ./result
nix build .#infrastructure-agent
```

## Available modules

### NixOS

#### Infrastructure agent `systemd` service

```nix
{
  services.newrelic-infra = {
    enable = true;

    # If you do not want to expose the config you can always do `config = import <PATH>`
    # and not checkout the file.
    config = {
      license_key = "ABC";
    };
  };
}
```

### Darwin

#### Infrastructure agent `launchd` daemon

```nix
{
  services.newrelic-infra = {
    enable = true;
    # If you do not want to expose the config you can always do `config = import <PATH>`
    # and not checkout the file.
    config = {
      license_key = "ABC";
    };
    logFile = ./path/to/file.log;
    errLogFile = ./path/to/errfile.log;
  };
}
```
