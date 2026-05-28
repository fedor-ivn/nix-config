{ config, flake, ... }:
{
  imports = [ flake.inputs.pi.homeModules.default ];

  programs.pi.coding-agent = {
    enable = true;
    skills = builtins.attrValues config.me.ai.skills;
    extensions = [ "${flake.inputs.clamor}/extensions/pi" ];
  };
}
