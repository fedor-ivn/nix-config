{ config, pkgs, lib, flake, ... }:
let
  whisplyPackage = flake.self.packages.${pkgs.stdenv.hostPlatform.system}.whisply;
in
{
  config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    sops.secrets."whisply/hf-token" = { };

    home.packages = [
      (pkgs.writeShellApplication {
        name = "whisply";
        text = ''
          HF_TOKEN=$(cat ${config.sops.secrets."whisply/hf-token".path})
          export HF_TOKEN
          exec ${lib.getExe' whisplyPackage "whisply"} "$@"
        '';
      })
    ];
  };
}
