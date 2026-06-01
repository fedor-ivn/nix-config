{ config, pkgs, lib, ... }:
let
  stalwartPort = if pkgs.stdenv.isLinux then 143 else 1143;
  gmailCredentials = config.sops.templates."gmail-credentials.json".path;
  mbsyncrc = config.sops.templates."mbsyncrc".path;
  stalwartConfig = config.sops.templates."stalwart-config.toml".path;
  stalwartDataDir = "${config.xdg.dataHome}/stalwart";
  logsDir = "${config.home.homeDirectory}/Library/Logs";

  # libsasl2 needs XOAUTH2 plugin co-located with the stock mechanisms.
  # Merge cyrus-sasl's default plugin dir with the XOAUTH2 plugin, expose via SASL_PATH.
  saslPluginsDir = pkgs.symlinkJoin {
    name = "sasl2-plugins-with-xoauth2";
    paths = [
      "${pkgs.cyrus_sasl.out}/lib/sasl2"
      "${pkgs.cyrus-sasl-xoauth2}/lib/sasl2"
    ];
  };

  isync = pkgs.symlinkJoin {
    name = "isync-xoauth2";
    paths = [ pkgs.isync ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/mbsync --set SASL_PATH ${saslPluginsDir}
    '';
  };

  # oauth2l with refresh_token-bearing creds. Full scope URL — `mail` alias not portable.
  passCmd = ''${pkgs.oauth2l}/bin/oauth2l fetch --output_format bare --credentials ${gmailCredentials} https://mail.google.com/'';
in
{
  sops.secrets = {
    "gmail/client-id" = { };
    "gmail/client-secret" = { };
    "gmail/refresh-token" = { };
    "stalwart/user-secret" = { };
    "stalwart/admin-secret" = { };
  };

  sops.templates."gmail-credentials.json" = {
    mode = "0600";
    content = ''
      {
        "client_id": "${config.sops.placeholder."gmail/client-id"}",
        "client_secret": "${config.sops.placeholder."gmail/client-secret"}",
        "refresh_token": "${config.sops.placeholder."gmail/refresh-token"}",
        "type": "authorized_user"
      }
    '';
  };

  sops.templates."mbsyncrc" = {
    mode = "0600";
    content = ''
      IMAPAccount gmail
      Host imap.gmail.com
      Port 993
      User ivnfedor@gmail.com
      PassCmd "${passCmd}"
      TLSType IMAPS
      AuthMechs XOAUTH2

      IMAPStore gmail-remote
      Account gmail

      IMAPStore stalwart
      Host 127.0.0.1
      Port ${toString stalwartPort}
      User fedorivn
      Pass ${config.sops.placeholder."stalwart/user-secret"}
      TLSType None
      AuthMechs LOGIN

      Channel inbox
      Far :gmail-remote:INBOX
      Near :stalwart:INBOX
      Create Both
      Expunge Both
      Sync All

      Channel sent
      Far :gmail-remote:"[Gmail]/Sent Mail"
      Near :stalwart:"Sent Items"
      Create Both
      Expunge Both
      Sync All

      Channel drafts
      Far :gmail-remote:"[Gmail]/Drafts"
      Near :stalwart:Drafts
      Create Both
      Expunge Both
      Sync All

      Channel trash
      Far :gmail-remote:"[Gmail]/Trash"
      Near :stalwart:"Deleted Items"
      Create Both
      Expunge Both
      Sync All

      Channel spam
      Far :gmail-remote:"[Gmail]/Spam"
      Near :stalwart:"Junk Mail"
      Create Both
      Expunge Both
      Sync All

      Group gmail
      Channel inbox
      Channel sent
      Channel drafts
      Channel trash
      Channel spam
    '';
  };

  # macOS: Stalwart config with secrets embedded (no systemd LoadCredential available)
  sops.templates."stalwart-config.toml" = lib.mkIf pkgs.stdenv.isDarwin {
    mode = "0600";
    content = ''
      [server]
      hostname = "localhost"

      [server.listener.imap]
      bind = ["127.0.0.1:${toString stalwartPort}"]
      protocol = "imap"

      [server.listener.jmap]
      bind = ["127.0.0.1:8080"]
      protocol = "http"

      [store.db]
      type = "sqlite"
      path = "${stalwartDataDir}/data.sqlite3"

      [storage]
      data = "db"
      fts = "db"
      blob = "db"
      lookup = "db"
      directory = "local"

      [directory.local]
      type = "memory"

      [[directory.local.principals]]
      class = "individual"
      name = "fedorivn"
      secret = "${config.sops.placeholder."stalwart/user-secret"}"
      email = ["ivnfedor@gmail.com"]

      [[directory.local.principals]]
      class = "admin"
      name = "admin"
      secret = "${config.sops.placeholder."stalwart/admin-secret"}"

      [imap.auth]
      allow-plain-text = true

      [resolver]
      type = "system"
      public-suffix = ["file://${pkgs.publicsuffix-list}/share/publicsuffix/public_suffix_list.dat"]

      [spam-filter]
      resource = "file://${pkgs.stalwart.spam-filter}/spam-filter.toml"

      [webadmin]
      path = "${config.xdg.cacheHome}/stalwart/webadmin"
      resource = "file://${pkgs.stalwart.webadmin}/webadmin.zip"

      [tracer.stdout]
      type = "stdout"
      level = "info"
      enable = true
    '';
  };

  # Linux: mbsync syncs Gmail → local Stalwart every 5 minutes
  systemd.user.services.mbsync-gmail = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Gmail to Stalwart IMAP sync";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${isync}/bin/mbsync -c ${mbsyncrc} gmail";
    };
  };

  systemd.user.timers.mbsync-gmail = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "Periodic Gmail sync timer";
    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      Unit = "mbsync-gmail.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # macOS: Stalwart + mbsync as launchd agents
  launchd.agents.stalwart = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.stalwart}/bin/stalwart"
        "--config" stalwartConfig
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${logsDir}/stalwart.log";
      StandardErrorPath = "${logsDir}/stalwart.log";
    };
  };

  launchd.agents.mbsync-gmail = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${isync}/bin/mbsync"
        "-c" mbsyncrc
        "gmail"
      ];
      StartInterval = 300;
      RunAtLoad = true;
      StandardOutPath = "${logsDir}/mbsync-gmail.log";
      StandardErrorPath = "${logsDir}/mbsync-gmail.log";
    };
  };
}
