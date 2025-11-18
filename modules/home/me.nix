# User configuration module
{ config, lib, ... }:
{
  options = {
    me = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "Your username as shown by `id -un`";
      };
      fullname = lib.mkOption {
        type = lib.types.str;
        description = "Your full name for use in Git config";
      };
      email = lib.mkOption {
        type = lib.types.str;
        description = "Your email for use in Git config";
      };
    };
  };

  config = {
    home.username = config.me.username;
  };

  accounts.email.accounts = let realName = config.me.fullname; in {
    Gmail = {
      address = "ivnfedor@gmail.com";
      flavor = "gmail.com";
      inherit realName;
      primary = true; # Mark as primary account

      thunderbird = {
        enable = true;
        settings = id: {
          "mail.smtpserver.smtp_${id}.authMethod" = 10;
          "mail.server.server_${id}.authMethod" = 10;
        };
      };
    };

    Blockscout = {
      address = "fedor@blockscout.com";
      flavor = "gmail.com";
      inherit realName;

      thunderbird = {
        enable = true;
        settings = id: {
          "mail.smtpserver.smtp_${id}.authMethod" = 10;
          "mail.server.server_${id}.authMethod" = 10;
        };
      };
    };
  };
}
