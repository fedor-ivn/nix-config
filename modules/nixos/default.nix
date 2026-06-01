{ flake, ... }:
{
  # Shared NixOS configuration for all hosts.
  imports = [
    flake.inputs.self.nixosModules.common
    flake.inputs.self.nixosModules.gui
    ./mail.nix
  ];

  # Common services
  services.openssh.enable = true;
}
