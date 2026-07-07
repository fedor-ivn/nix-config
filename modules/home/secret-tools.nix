{ flake, ... }:
{
  # Some tool modules live in the private `secrets` flake. Darwin-only,
  # default off.
  imports = [
    flake.inputs.secrets.homeModules.secretTool1
    flake.inputs.secrets.homeModules.secretTool2
  ];
}
