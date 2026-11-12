{
  description = "yurice minimal yet pretty configuration, which brings keyboard oriented workflow and takes the best out of windows, macos, and other linux rices";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
  in {
    nixosModules.default = import ./nix/nixos.nix self;
    homeModules.default = import ./nix/home.nix self;

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
