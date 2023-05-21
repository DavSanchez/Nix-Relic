# You can build the below packages using 'nix build .#example' or (legacy) 'nix-build -A example'
{pkgs ? import <nixpkgs> {}}: {
  infrastructure-agent = pkgs.callPackage ./infrastructure-agent.nix {
    inherit (pkgs.darwin.apple_sdk.frameworks) CoreFoundation IOKit Security;
    buildGoModule = pkgs.buildGo119Module;
  };
}
