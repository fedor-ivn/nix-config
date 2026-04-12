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
    {
      packages.whisply = pkgs.writeShellApplication {
        name = "whisply";
        runtimeInputs = [
          (pythonSet.mkVirtualEnv "whisply-env" workspace.deps.default)
          pkgs.ffmpeg
        ];
        text = ''exec whisply "$@"'';
      };
    };
}
