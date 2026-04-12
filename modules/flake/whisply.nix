{ inputs, ... }:
let
  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = inputs.whisply-src;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };
in
{
  perSystem = { pkgs, ... }:
    let
      python = pkgs.python3;

      pythonSet = (pkgs.callPackage inputs.pyproject-nix.build.packages {
        inherit python;
      }).overrideScope (
        pkgs.lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          overlay
          # antlr4-python3-runtime uses setuptools but doesn't declare it
          (final: prev: {
            antlr4-python3-runtime = prev.antlr4-python3-runtime.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.setuptools ];
            });
          })
        ]
      );
    in
    let
      venv = pythonSet.mkVirtualEnv "whisply-env" workspace.deps.default;
    in
    {
      packages.whisply = pkgs.symlinkJoin {
        name = "whisply";
        paths = [ venv ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/whisply \
            --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.ffmpeg ]}
        '';
      };
    };
}
