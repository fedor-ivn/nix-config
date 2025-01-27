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

    "Innopolis University" = {
      address = "f.ivanov@innopolis.university";
      userName = "f.ivanov@innopolis.university";
      inherit realName;

      thunderbird.enable = true;
      imap = {
        host = "mail.innopolis.ru";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "mail.innopolis.ru";
        port = 587;
        tls.enable = true;
      };
    };
  };
}
