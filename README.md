# NixObs

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

This is a collection of some observability tools packaged as Nix Flakes and accompanied by modules.

## Available packages

### New Relic Infrastructure Agent

```sh
nix shell .#infrastructure-agent

# or build the package and find the outputs in ./result
nix build .#infrastructure-agent
```

## Available modules

It might be possible that the modules defined here reference packages that are not yet present in `nixpkgs`. If you encounter this problem, add this flake's default overlay to your `nixpkgs.overlays` config:

```nix
{
  nixpkgs = {
    overlays = [
      inputs.nixobs.overlays.default
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
