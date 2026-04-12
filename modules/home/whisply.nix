{ pkgs, flake, ... }:
{
  home.packages = [
    flake.self.packages.${pkgs.stdenv.hostPlatform.system}.whisply
  ];
}
