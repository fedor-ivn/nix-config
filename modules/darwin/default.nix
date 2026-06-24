{ flake, config, ... }:
{
  imports = [
    ../nixos/common/users.nix
    flake.inputs.nix-homebrew.darwinModules.nix-homebrew
    ./system.nix
    ./aerospace.nix
    ./homebrew.nix
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
