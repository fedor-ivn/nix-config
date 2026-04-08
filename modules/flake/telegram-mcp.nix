{ inputs, ... }:
let
  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = inputs.telegram-mcp-src;
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
          inputs.pyproject-build-systems.overlays.wheel
          overlay
          # pyaes uses setuptools but doesn't declare it as a build dependency
          (final: prev: {
            pyaes = prev.pyaes.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.setuptools ];
            });
          })
        ]
      );
    in
    {
      packages.telegram-mcp = pythonSet.mkVirtualEnv "telegram-mcp-env" workspace.deps.default;
    };
}
