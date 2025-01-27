{ pkgs, ... }:

{
  programs.thunderbird = {
    enable = true;
    # TODO: warning: fedorivn profile: Thunderbird packages are not yet
    # supported on Darwin. You can still use this module to manage your
    # accounts and profiles by setting 'programs.thunderbird.package' to a
    # dummy value, for example using 'pkgs.runCommand'.
    package = pkgs.runCommand "thunderbird-dummy" { } "mkdir -p $out";
    profiles.fedorivn = {
      isDefault = true;
    };
  };
}
