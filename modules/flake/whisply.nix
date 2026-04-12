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
