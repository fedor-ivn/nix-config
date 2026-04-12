{ pkgs, flake, ... }:
let
  whisplyPackage = flake.self.packages.${pkgs.stdenv.hostPlatform.system}.whisply;
in
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "whisply";
      runtimeInputs = [ whisplyPackage pkgs.ffmpeg ];
      text = ''exec whisply "$@"'';
    })
  ];
}
