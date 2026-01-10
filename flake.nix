{
  description = "Ziglings nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem =
        { pkgs, system, ... }:
        let
          zig = inputs.zig.packages.${system}."0.15.2";
        in
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                inherit zig;
              })
            ];
            config = { };
          };

          devShells.default = pkgs.mkShell {
            name = "zig_life-dev";

            packages = [
              zig
              pkgs.zls
              pkgs.biome
            ];
          };
        };
    };
}
