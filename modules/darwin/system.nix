{ flake, lib, ... }:
let
  self = flake.inputs.self;

  # Roots the Mozilla bundle doesn't carry, trusted in two stores that don't
  # read each other: the Nix-built bundle below and the System keychain.
  trustedCerts = [
    ../../certs/russian-trusted-root-ca.pem
    ../../certs/tinkoff-root-ca.pem
  ];
in
{
  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    WindowManager.EnableStandardClickToShowDesktop = false;

    CustomUserPreferences = {
      GlobalPreferences = {
        NSUserDictionaryReplacementItems = map (item: { on = 1; } // item) [
          {
            replace = ">=";
            "with" = "≥";
          }
          {
            replace = "<=";
            "with" = "≤";
          }
          {
            replace = "!=";
            "with" = "≠";
          }
          {
            replace = "->";
            "with" = "→";
          }
          {
            replace = "дy";
            "with" = "доброе утро";
          }
          {
            replace = "есчо";
            "with" = "если что";
          }
          {
            replace = "кмк";
            "with" = "как мне кажется";
          }
          {
            replace = "мб";
            "with" = "может быть";
          }
          {
            replace = "плз";
            "with" = "пожалуйста";
          }
          {
            replace = "сн";
            "with" = "спокойной ночи";
          }
          {
            replace = "спс";
            "with" = "спасибо";
          }
        ];
      };
    };

    finder = {
      CreateDesktop = false;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
      FXDefaultSearchScope = "SCcf";
    };

    dock = {
      mru-spaces = false;
      autohide = true;
    };

    trackpad = {
      FirstClickThreshold = 0;
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleScrollerPagingBehavior = true;
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      AppleShowScrollBars = "WhenScrolling";
      InitialKeyRepeat = 12;
      KeyRepeat = 2;
      NSDocumentSaveNewDocumentsToCloud = false;
      "com.apple.keyboard.fnState" = true;
    };
  };

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Concatenated into `/etc/ssl/certs/ca-certificates.crt` for everything that
  # reads a bundle file: nix (NIX_SSL_CERT_FILE), nixpkgs curl/git, and node
  # via NODE_EXTRA_CA_CERTS below. Same option name as NixOS, so `certs/` is
  # the one list for both platforms. TINKOFFBANK-ROOTCA signs the corp LBaaS CA
  # that fronts internal services.
  security.pki.certificateFiles = trustedCerts;

  # node ships its own root store and consults neither of the above unless
  # pointed at a bundle. mkDefault so a host behind TLS interception can aim it
  # at a keychain-derived superset instead.
  environment.variables.NODE_EXTRA_CA_CERTS =
    lib.mkDefault "/etc/ssl/certs/ca-certificates.crt";

  # Same list into the keychain.
  system.activationScripts.extraActivation.text = ''
    # Match on fingerprints rather than common names: the name this guard used
    # to grep for had drifted from the file it guarded, so it would have
    # re-added the cert on every activation.
    trusted=$(/usr/bin/security find-certificate -a -Z \
      /Library/Keychains/System.keychain || true)
    for cert in ${lib.concatMapStringsSep " " toString trustedCerts}; do
      hash=$(/usr/bin/openssl x509 -in "$cert" -noout -fingerprint -sha1 \
        | tr -d ':' | cut -d= -f2)
      case "$trusted" in
        *"SHA-1 hash: $hash"*) continue ;;
      esac
      echo "Trusting $(basename "$cert") in the System keychain..." >&2
      /usr/bin/security add-trusted-cert -d -r trustRoot \
        -k /Library/Keychains/System.keychain "$cert"
    done
  '';

  programs.zsh.enable = true;
  services.tailscale.enable = true;
  services.openssh = {
    enable = true;
    extraConfig = ''
      ClientAliveInterval 30
      ClientAliveCountMax 3
    '';
  };
  system.configurationRevision = self.rev or self.dirtyRev or null;
}
