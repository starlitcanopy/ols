{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    odin.url = "github:starlitcanopy/odin";
  };

  outputs =
    inputs:
    let
      perSystem =
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.odin.overlays.default
              inputs.self.overlays.default
            ];
          };
        in
        {
          packages = { inherit (pkgs) ols; };
        };
    in
    {
      overlays.default = final: prev: {
        ols = prev.ols.overrideAttrs (og: rec {
          version = "unstable-2025-05-19";
          src = final.lib.fileset.toSource {
            root = ./.;
            fileset = final.lib.fileset.unions [
              ./build.sh
              ./odinfmt.sh
              ./builtin
              ./src
              ./tools
            ];
          };

          postPatch = ''
            substituteInPlace build.sh \
              --replace-fail \
                'version="$(git describe --tags --abbrev=7)"' \
                'version="${version}"'
            ${og.postPatch}
          '';

          installPhase = ''
            runHook preInstall

            install -Dm755 ols odinfmt -t $out/bin/
            cp      -r     builtin        $out/bin/
            wrapProgram $out/bin/ols --set-default ODIN_ROOT ${final.odin}/share

            runHook postInstall
          '';
        });
      };
    }
    // inputs.flake-utils.lib.eachSystem (with inputs.flake-utils.lib.system; [
      x86_64-linux
    ]) perSystem;
}
