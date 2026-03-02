{ lib, config, ... }:
lib.mkIf config.me.isMainMachine {
  # Lima reads ~/.lima/<instance>/lima.yaml only during `limactl create`.
  # If this template changes, recreate the VM:
  # `limactl delete nixos-vm && limactl create --name=nixos-vm ~/.lima/nixos-vm/lima.yaml`.
  home.file.".lima/nixos-vm/lima.yaml".source = ../darwin/lima-nixos-vm.yaml;
}
