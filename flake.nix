{
  description = "Collection of infra observability tools packaged for Nix and accompanied by modules";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }@inputs:
    let
      # Supported systems for flake packages, shell, etc.
      # x86_64-darwin was dropped from nixpkgs in 26.11
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      # This is a function that generates an attribute by calling a function you
      # pass to it, with each system as an argument
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system: import ./pkgs { pkgs = nixpkgs.legacyPackages.${system}; });

      nixosModules = import ./modules/nixos;

      darwinModules = import ./modules/darwin;

      overlays = import ./overlays { inherit inputs; };

      formatter = forAllSystems (
        system:
        nixpkgs.legacyPackages.${system}.nixfmt
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixfmt
              statix
              deadnix
            ];
          };
        }
      );
    };
}