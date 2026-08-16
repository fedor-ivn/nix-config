{ flake, config, ... }:
{
  imports = [
    ../nixos/common/users.nix
    flake.inputs.nix-homebrew.darwinModules.nix-homebrew
    ./system.nix
    ./aerospace.nix
    ./homebrew.nix
    ./overlays.nix
  ];

  nix-homebrew = {
    enable = true;
    user = config.system.primaryUser;
    taps = {
      "homebrew/homebrew-core" = flake.inputs.homebrew-core;
      "homebrew/homebrew-cask" = flake.inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = flake.inputs.homebrew-bundle;
    };
    mutableTaps = false;
  };

  # Mirror the nix-homebrew taps into the generated Brewfile. Without this, the
  # taps exist on disk (pinned read-only by nix-homebrew) but are absent from
  # the Brewfile, so `homebrew.onActivation.cleanup = "zap"` decides to untap
  # them — which first uninstalls EVERY cask belonging to those taps. The untap
  # then fails on the read-only symlink (`mutableTaps = false`), leaving all
  # casks wiped and re-triggering the same loop on the next activation.
  homebrew.taps = builtins.attrNames config.nix-homebrew.taps;

  home-manager.sharedModules = [
    flake.inputs.spicetify-nix.homeManagerModules.default
    (
      { pkgs, flake, ... }:
      {
        # TODO: There's some problems with spotify dmg, so I disabled it for now.
        programs.spicetify = {
          enable = true;
          enabledExtensions = with flake.inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system}.extensions; [
            adblockify
            hidePodcasts
            shuffle
          ];
        };
      }
    )
  ];
}
