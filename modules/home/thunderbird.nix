{ pkgs, ... }:

{
  programs.thunderbird = {
    enable = true;
    profiles.fedorivn = {
      isDefault = true;
    };
  };
}
