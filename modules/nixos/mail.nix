{ flake, config, lib, ... }:
{
  imports = [
    flake.inputs.sops-nix.nixosModules.sops
  ];

  sops.age.keyFile = "/home/fedorivn/.config/sops/age/keys.txt";
  sops.defaultSopsFile = "${flake.inputs.self}/secrets.yaml";

  sops.secrets."stalwart/admin-secret" = { };
  sops.secrets."stalwart/user-secret" = {
    owner = "fedorivn";
    mode = "0400";
  };

  services.stalwart = {
    enable = true;
    stateVersion = "26.05";
    openFirewall = false;

    credentials = {
      admin_secret = config.sops.secrets."stalwart/admin-secret".path;
      user_secret = config.sops.secrets."stalwart/user-secret".path;
    };

    settings = {
      server.listener = {
        imap = {
          bind = [ "127.0.0.1:143" ];
          protocol = "imap";
        };
        jmap = {
          bind = [ "127.0.0.1:8080" ];
          protocol = "http";
        };
      };

      # Memory directory: users declared in config, no DB needed
      directory.local = {
        type = "memory";
        principals = [
          {
            class = "individual";
            name = "fedorivn";
            secret = "%{file:/run/credentials/stalwart.service/user_secret}%";
            email = [ "ivnfedor@gmail.com" ];
          }
          {
            class = "admin";
            name = "admin";
            secret = "%{file:/run/credentials/stalwart.service/admin_secret}%";
          }
        ];
      };

      storage.directory = "local";

      # Allow PLAIN auth over non-TLS on localhost
      imap.auth.allow-plain-text = true;
    };
  };
}
