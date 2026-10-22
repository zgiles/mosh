{
  description = "mosh (mobile shell) with robustness and security fixes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Reuse the nixpkgs package, built from this tree. Its upstream
      # protobuf-23 fetchpatch (eee1a8cf) is already in this tree, so drop it.
      override = mosh: mosh.overrideAttrs (old: {
        version = "1.4.0-unstable-${self.lastModifiedDate or "dirty"}";
        src = self;
        patches = lib.filter (p: !(lib.hasInfix "eee1a8cf" (toString p))) old.patches;
      });
    in
    {
      overlays.default = final: prev: { mosh = override prev.mosh; };

      packages = forAllSystems (pkgs: {
        default = override pkgs.mosh;
        mosh = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell { inputsFrom = [ (override pkgs.mosh) ]; };
      });
    };
}
