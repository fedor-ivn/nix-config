{ flake, pkgs, ... }:
let
  secrets = flake.inputs.secrets.values;
in
{
  imports = [ flake.inputs.self.darwinModules.default ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = 5;

  system.primaryUser = "ext.fivanov";
  managedUsers = [ "ext.fivanov" ];

  networking.hostName = "fedorivns-tbank-mbp";
  networking.localHostName = "fedorivns-tbank-mbp";
  networking.computerName = "fedorivns-tbank-mbp";

  # Corp network does TLS interception (Tinkoff MITM CA). nix's bundled OpenSSL
  # uses ONLY the cert file (unlike macOS curl, which also consults the Keychain),
  # so it needs a bundle containing BOTH the corp CAs (System.keychain) AND the
  # public roots (SystemRootCertificates) — some endpoints pass through with
  # genuine certs, others are intercepted.
  #
  # Regenerate on every activation so it self-heals when corp CAs rotate.
  system.activationScripts.extraActivation.text = ''
    echo "regenerating /etc/nix/all-certs.pem (corp MITM CAs + public roots)..." >&2
    /usr/bin/security find-certificate -a -p /Library/Keychains/System.keychain > /etc/nix/all-certs.pem
    /usr/bin/security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain >> /etc/nix/all-certs.pem
    chmod 0644 /etc/nix/all-certs.pem
  '';


  home-manager.users."ext.fivanov" = { config, pkgs, ... }: {
    programs = {
      codex.enable = false;
      whisply.enable = false;
      secretTool1.enable = true;
      secretTool2.enable = true;
      glab.config.enable = true;

      git.includes =
        let
          helper = pkgs.writeShellScript "git-credential-github-pat" ''
            test "$1" = get || exit 0
            echo username=fedor-ivn
            echo password=$(cat ${config.sops.secrets."github/pat".path})
          '';
        in
        [{
          path = pkgs.writeText "corp-github-credentials.gitconfig" ''
            [credential "https://github.com"]
              helper = !${helper}
          '';
        }];
    };

    sops.secrets."github/pat" = { };
  };

  # taskchampion (the sync library in taskwarrior3) defaults to bundled Mozilla
  # root store (tls-webpki-roots), which doesn't include the Tinkoff NGFW CA.
  # Switch to tls-native-roots so it reads from the macOS Keychain instead.
  nixpkgs.overlays = [
    (final: prev: {
      taskwarrior3 = prev.taskwarrior3.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          sed -i 's/^\[features\]/[features]\ndefault = ["tls-native-roots"]/' \
            src/taskchampion-cpp/Cargo.toml
        '';
      });
    })
  ];


  # ssl-cert-file covers the nix daemon (substitution, fixed-output fetches);
  # NIX_SSL_CERT_FILE covers client-side flake fetches and overrides the default
  # the nix profile would otherwise export (which lacks the corp CAs).
  nix.settings.ssl-cert-file = "/etc/nix/all-certs.pem";
  environment.variables.NIX_SSL_CERT_FILE = "/etc/nix/all-certs.pem";
}
