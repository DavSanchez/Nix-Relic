# You can build the below packages using 'nix build .#example' or (legacy) 'nix-build -A example'
{pkgs ? import <nixpkgs> {}}: {
  infrastructure-agent = pkgs.callPackage ./infrastructure-agent.nix {};
  ocb = pkgs.callPackage ./ocb.nix {};
}
