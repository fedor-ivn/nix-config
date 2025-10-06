{ ... }:
let
  realName = "Fedor Ivanov";
in
{
  accounts.email.accounts = {
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
