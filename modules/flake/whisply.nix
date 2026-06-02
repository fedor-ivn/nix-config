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
          # Packages that use setuptools as build backend but don't declare it
          (final: prev:
            let
              addSetuptools = name: prev.${name}.overrideAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.setuptools ];
              });
            in
            {
              antlr4-python3-runtime = addSetuptools "antlr4-python3-runtime";
              docopt = addSetuptools "docopt";
              julius = addSetuptools "julius";
            })
          # mlx ships core.cpython-*.so with rpath @loader_path/lib, but libmlx.dylib
          # is in a sibling package (mlx-metal). In a normal pip install both land in
          # the same site-packages/mlx/ directory; in Nix they are separate derivations.
          # Symlink mlx-metal's lib/ into the mlx derivation so @loader_path resolves.
          (final: prev: pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
            mlx = prev.mlx.overrideAttrs (old: {
              postInstall = (old.postInstall or "") + ''
                ln -s ${final.mlx-metal}/${python.sitePackages}/mlx/lib \
                  "$out/${python.sitePackages}/mlx/lib"
              '';
            });
          })
        ]
      );
    in
    let
      venv = pythonSet.mkVirtualEnv "whisply-env" {
        whisply = [ "app" ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ "mlx" ];
      };
    in
    {
      # Darwin-only: nvidia-cufile (transitive dep) needs RDMA libs absent on Linux
      packages = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        whisply = pkgs.runCommand "whisply" {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        } ''
          makeWrapper ${venv}/bin/whisply $out/bin/whisply \
            --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.ffmpeg ]}
        '';
      };
    };
}
