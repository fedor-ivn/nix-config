{ pkgs, ... }:

{
  programs.thunderbird = {
    enable = true;

    # On Darwin, Thunderbird packages are not yet supported. Use a dummy package.
    # On Linux, use the real Thunderbird package from pkgs.
    package =
      if pkgs.stdenv.hostPlatform.isDarwin then
        pkgs.runCommand "thunderbird-dummy" { } "mkdir -p $out"
      else
        pkgs.thunderbird;

    profiles.fedorivn = {
      isDefault = true;
    };
  };
}
