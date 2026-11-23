{ config, ... }:
{
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  nix.buildMachines = [
    {
      hostName = "fedorivns-homelab";
      sshUser = "fedorivn";
      protocol = "ssh-ng";
      sshKey = "${config.system.primaryUserHome}/.ssh/nix-builder";
      systems = [ "x86_64-linux" "aarch64-linux" ];
      maxJobs = 6;
      speedFactor = 4;
      supportedFeatures = [ "benchmark" "big-parallel" "kvm" "nixos-test" ];
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSU9RSmhoM0RhVGRzMTRmSUNxVXY5RDZNY0JEZ0s5MzJsbTAwUzFiY0U2ZXg=";
    }
  ];
}
