{ ... }:

{
  programs.thunderbird = {
    enable = true;
    profiles.fedorivn = {
      isDefault = true;
      settings = {
        "mail.serverDefaultStoreContractID" = "@mozilla.org/msgstore/maildirstore;1";
      };
    };
  };
}
