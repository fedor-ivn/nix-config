{ config, lib, pkgs, ... }:
let
  encodedEmail = builtins.replaceStrings [ "@" ] [ "%40" ] config.me.email;
  oauthParams = "client_id=${config.sops.placeholder."aerc/client-id"}&client_secret=${config.sops.placeholder."aerc/client-secret"}&token_endpoint=https://oauth2.googleapis.com/token";
  openHtml = pkgs.writeShellScript "aerc-open-html" ''
    tmp=$(mktemp /tmp/XXXXXX.html)
    cp "$1" "$tmp"
    open "file://$tmp"
  '';
in
{
  programs.aerc = {
    enable = false;
    extraConfig = {
      general."unsafe-accounts-conf" = true;
      viewer.alternatives = "text/html,text/plain";
      filters."text/plain" = "bat -p --color=always";
      filters."text/html" = "w3m -T text/html";
      openers."text/html" = "${openHtml}";
    };
    extraBinds = {
      messages = {
        d = ":read<Enter>:move [Gmail]/Trash<Enter>";
      };
      "messages:folder=[Gmail]/Trash" = {
        d = ":choose -o y 'Permanently delete?' delete-message<Enter>";
      };
      "messages:folder=[Gmail]/Spam" = {
        d = ":choose -o y 'Permanently delete?' delete-message<Enter>";
      };
    };
  };

  sops.secrets = {
    "aerc/client-id" = { };
    "aerc/client-secret" = { };
    "aerc/refresh-token" = { };
  };

  sops.templates."aerc-accounts.conf" = {
    mode = "0600";
    content = ''
      [Gmail]
      source      = imaps+oauthbearer://${encodedEmail}:${config.sops.placeholder."aerc/refresh-token"}@imap.gmail.com:993?${oauthParams}
      outgoing    = smtps+oauthbearer://${encodedEmail}:${config.sops.placeholder."aerc/refresh-token"}@smtp.gmail.com:465?${oauthParams}
      default     = INBOX
      copy-to     =
      from        = ${config.me.fullname} <${config.me.email}>
      archive     = [Gmail]/All Mail
      trash       = [Gmail]/Trash
    '';
  };

  home.activation.linkAercAccounts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    AERC_CONF_DIR="${config.xdg.configHome}/aerc"
    mkdir -p "$AERC_CONF_DIR"
    ln -sf "${config.sops.templates."aerc-accounts.conf".path}" "$AERC_CONF_DIR/accounts.conf"
  '';
}
