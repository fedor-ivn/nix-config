{ config, lib, ... }:
{
  options.programs.glab.config.enable =
    lib.mkEnableOption "glab GitLab config";

  config = lib.mkIf config.programs.glab.config.enable {
    sops.secrets."gitlab/hostname" = { };
    sops.secrets."gitlab/pat" = { };

    sops.templates."glab-cli-config.yml".mode = "0600";
    sops.templates."glab-cli-config.yml".content = ''
      hosts:
        ${config.sops.placeholder."gitlab/hostname"}:
            token: ${config.sops.placeholder."gitlab/pat"}
            container_registry_domains: ${config.sops.placeholder."gitlab/hostname"},${config.sops.placeholder."gitlab/hostname"}:443,registry.${config.sops.placeholder."gitlab/hostname"}
            api_host: ${config.sops.placeholder."gitlab/hostname"}
            git_protocol: ssh
          api_protocol: https
            user: ext.fivanov
    '';

    home.file.".config/glab-cli/config.yml".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."glab-cli-config.yml".path;
  };
}
