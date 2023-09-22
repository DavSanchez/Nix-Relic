{
  description = "Collection of observability tools packaged for Nix and accompanied by modules";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    # self,
    nixpkgs,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  in {
    packages = forAllSystems (system: import ./pkgs {pkgs = nixpkgs.legacyPackages.${system};});

    nixosModules = import ./modules/nixos;

    darwinModules = import ./modules/darwin;

    overlays = {
      default = self: super: import ./pkgs {pkgs = self;};
    };
  };
}
