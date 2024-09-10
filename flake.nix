{
  description = "tuatara";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
  }:
    utils.lib.eachDefaultSystem
    (system: let
      pkgs = import nixpkgs {inherit system;};

      inherit (pkgs) stdenv;
    in {
      packages = {
        default = stdenv.mkDerivation rec {
          name = "tuatara";

          src = ./.;

          nativeBuildInputs = with pkgs; [zig_0_13];

          buildPhase = ''
            runHook preBuild
            zig build -Doptimize=ReleaseFast
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            install -Dm755 -t $out/bin zig-out/bin/${name}
            runHook postInstall
          '';

          env = {
            XDG_CACHE_HOME = "xdg_cache";
          };
        };
      };

      apps.default = utils.lib.mkApp {drv = self.packages.${system}.default;};
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [zig_0_13];
      };
    });
}
