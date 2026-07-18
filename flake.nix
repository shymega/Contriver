{
  description = "A fault-tolerant REAPI and CAS implementation, written in Elixir, designed for high-availability, speed, and ease-of-use.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    systems.url = "github:nix-systems/triplet";
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";

      inputs.flake-compat.follows = "flake-compat";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs: let
    inherit (inputs) self devenv nixpkgs;

    forEachSystem = let
      systems = import inputs.systems;
      genPkgs = system: nixpkgs.legacyPackages.${system};
      inherit (nixpkgs.lib) genAttrs;
    in
      f: genAttrs systems (system: f (genPkgs system));
  in {
    packages = forEachSystem (pkgs: let
      inherit (pkgs) beamPackages lib;
      inherit (pkgs.stdenv.hostPlatform) system;
    in {
      contriver = beamPackages.mixRelease rec {
        pname = "contriver";
        version = "0.1.0";
        src = self;

        mixFodDeps = beamPackages.fetchMixDeps {
          inherit pname src version;

          hash = "sha256-zQkTCaYCdkHnvNNtrGBuwVU/jTJXpW7MW/GgaB/6fa4=";
        };

        passthru = {
          inherit mixFodDeps;

          elixirPackage = beamPackages.elixir;

          updateScript = pkgs.nix-update-script {};
        };
      };
      default = self.packages.${system}.contriver;
      docker = let
        entrypoint = pkgs.writeShellScript "entrypoint" ''
          /bin/contriver start
        '';
      in
        pkgs.dockerTools.buildLayeredImage {
          config.Cmd = ["./${entrypoint}"];
          contents = with self.packages.${system}; [contriver];
          name = "gitlab.codethink.co.uk:5000/codethings/domrodriguez/contriver";
          tag = "latest";
        };
    });

    devShells.default = forEachSystem (pkgs:
      devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [
          ({pkgs, ...}: {
            languages = {
              elixir.enable = true;
              erlang.enable = true;
              nix.enable = true;
              shell.enable = true;
            };
            devcontainer.enable = true;
            difftastic.enable = true;
            pre-commit.hooks = {
              actionlint.enable = true;
              markdownlint.enable = true;
              nixpkgs-fmt.enable = true;
              shellcheck.enable = true;
              shfmt.enable = true;
              statix.enable = true;
            };
          })
        ];
      });

    apps = forEachSystem (pkgs: let
      inherit (pkgs.stdenv.hostPlatform) system;
    in {
      docker = let
        drv = self.packages.${system}.docker;
      in {
        type = "app";
        inherit drv;
      };
      default = let
        drv = self.packages.${system}.default;
      in {
        type = "app";
        inherit drv;
      };
    });
  };
}
