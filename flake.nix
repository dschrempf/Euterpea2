{
  description = "Haskell development environment";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

  outputs =
    { self
    , flake-utils
    , nixpkgs
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        haskellPackageNames = [
          "Euterpea"
        ];
        ghcVersion = "ghc90";
        haskellMkPackage = hps: nm: hps.callCabal2nix nm (./. + "/${nm}") { };
        haskellOverlay = (
          selfn: supern: {
            haskellPackages = supern.haskell.packages.${ghcVersion}.override {
              overrides = selfh: superh:
                {
                  Euterpea = selfh.callCabal2nix "Euterpea" ./. rec { };
                };
            };
          }
        );
        overlays = [ haskellOverlay ];
        pkgs = import nixpkgs {
          inherit system;
          inherit overlays;
        };
        hpkgs = pkgs.haskellPackages;
        EuterpeaPkgs = nixpkgs.lib.genAttrs haskellPackageNames (n: hpkgs.${n});
        EuterpeaPkgsDev = builtins.mapAttrs (_: x: pkgs.haskell.lib.doBenchmark x) EuterpeaPkgs;
      in
      {
        packages = EuterpeaPkgs // { default = EuterpeaPkgs.Euterpea; };

        devShells.default = hpkgs.shellFor {
          # shellHook =
          #   let
          #     scripts = ./scripts;
          #   in
          #   ''
          #     export PATH="${scripts}:$PATH"
          #   '';
          packages = _: (builtins.attrValues EuterpeaPkgsDev);
          nativeBuildInputs = with pkgs; [
            # See https://github.com/NixOS/nixpkgs/issues/59209.
            bashInteractive

            # Haskell toolchain.
            hpkgs.cabal-fmt
            hpkgs.cabal-install
            hpkgs.haskell-language-server
          ];
          buildInputs = with pkgs; [
          ];
          doBenchmark = true;
          # withHoogle = true;
        };
      }
    );
}
