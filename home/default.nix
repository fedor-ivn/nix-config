{
  pkgs,
  username,
  pkgs-stable,
  spicetify-nix,
  ...
}:
let
  spicetifyPkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in 
{
  nixpkgs.config.allowUnfree = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${username} = {
    imports = [
      spicetify-nix.homeManagerModules.default
      ./email.nix
      ./programs/alacritty.nix
      ./programs/bat.nix
      ./programs/direnv.nix
      ./programs/fzf.nix
      ./programs/git.nix
      ./programs/shell-applications.nix
      ./programs/taskwarrior.nix
      ./programs/thunderbird.nix
      ./programs/vscode.nix
      ./programs/zoxide.nix
      ./programs/zsh.nix
    ];

    programs.home-manager.enable = true;
    programs.tmux.enable = true;

    programs.spicetify = {
      enable = true;
      enabledExtensions = with spicetifyPkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle
      ];
    };

    home = {
      inherit username;
      homeDirectory = "/Users/${username}";
      stateVersion = "24.05";
      shellAliases = {
        t = "task";
        tt = "taskwarrior-tui";
      };
    };

    home.packages = with pkgs; [
      slack
      qbittorrent
      obsidian
      jetbrains-mono
      # hoppscotch
      postman

      # Touch ID unlock support on macOS isn't working for nixpkgs build of
      # KeePassXC, so the Homebrew version is used instead.
      # TODO: Track this issue - https://github.com/NixOS/nixpkgs/issues/241103
      # keepassxc

      raycast
      monitorcontrol
      stats

      alt-tab-macos

      tealdeer
      dig
      jq
      python313
      gh
      podman
      podman-compose
      dust
      taskwarrior-tui

      syncthing

    ] ++ (with pkgs-stable; [
      prismlauncher
      zoom-us
    ]);

  };

  # services.syncthing is not available for darwin, so syncthing is started via
  # launchd instead.
  launchd.user.agents = {
    syncthing = {
      command = "${pkgs.syncthing}/bin/syncthing";
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/syncthing.out.log";
        StandardErrorPath = "/tmp/syncthing.err.log";
      };
    };
  };
}
