{ self, system, pkgs, username, hostname, ... }: {
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    environment.systemPackages = with pkgs; [
        # darwin.xcode
        htop
        neovim
        tmux
        neofetch
    ];

    users.users.fedorivn = {
        name = "fedorivn";
        home = "/Users/fedorivn";
    };

    security.pam.enableSudoTouchIdAuth = true;
    system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = false;
    system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;
    system.defaults.dock.autohide = true;
    # system.defaults.dock.autohide-delay = 0.24;
    # system.defaults.dock.autohide-time-modifier = 1.0;

    services.nix-daemon.enable = true;
    nix = {
        gc.automatic = true;
        settings = {
        experimental-features = [ "nix-command" "flakes" ];
            auto-optimise-store = true;
        };
    };

    networking = {
        hostName = hostname;
    };

    # Create /etc/zshrc that loads the nix-darwin environment.
    programs.zsh.enable = true;

    # Set Git commit hash for darwin-version.
    system.configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 5;

    # The platform the configuration will be used on.
    nixpkgs.hostPlatform = system;

    services.tailscale.enable = true;

    # https://github.com/LnL7/nix-darwin/issues/786
    system.activationScripts.extraActivation.text = ''
    softwareupdate --install-rosetta --agree-to-license
    '';
}
