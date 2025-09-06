{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flakeParts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
  };

  outputs = inputs@{ self, nixpkgs, flakeParts, ... }:
    flakeParts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.haskell-flake.flakeModule
      ];

      perSystem = { self', pkgs, ... }: {
        haskellProjects.default = {
          projectFlakeName = "sgillespie-github-io";

          devShell = {
            enable = true;

            tools = hsPkgs: {
              cabal-install = hsPkgs.cabal-install;
              haskell-language-server = hsPkgs.haskell-language-server;
            };
          };
        };

        packages.default = self'.packages.sgillespie-github-io;
      };
    };
}
