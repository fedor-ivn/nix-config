{ flake, ... }:
{
  imports = [
    flake.inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    imports = [ ./nixvim.nix ];
  };
}
