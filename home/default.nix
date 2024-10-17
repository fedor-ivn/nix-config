{
  pkgs,
  username,
  pkgs-stable,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${username} = {
    imports = [
      ./programs/zsh.nix
      ./programs/direnv.nix
      ./programs/git.nix
      ./programs/vscode.nix
      ./programs/alacritty.nix
    ];

    programs.home-manager.enable = true;
    programs.tmux.enable = true;
    # programs.thunderbird = {
    #     profiles.fedorivn = {
    #       isDefault = true;
    #     };
    # };

    home = {
      inherit username;
      homeDirectory = "/Users/${username}";
      stateVersion = "24.05";
    };

    home.packages = with pkgs; [
      keepassxc
      slack
      # transmission
      obsidian
      jetbrains-mono
      # hoppscotch
      postman

      raycast
      monitorcontrol
      stats

      tealdeer
      dig
      jq
      python313
      gh
      podman

      dust

      syncthing
    ];
  };

  # services.syncthing is not available for darwin, so syncthing is started via
  # launchd instead.
  launchd.user.agents.syncthing = {
    command = "${pkgs.syncthing}/bin/syncthing";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/syncthing_fedorivn.out.log";
      StandardErrorPath = "/tmp/syncthing_fedorivn.err.log";
    };
  };
}
