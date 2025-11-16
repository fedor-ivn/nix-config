pkgs:

with pkgs.vscode-extensions;
[
  stkb.rewrap
]
++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
  # {
  #   name = "ms-vscode";
  #   publisher = "remote-explorer";
  # }
  #   {
  #   name = "ms-vscode-remote";
  #   publisher = "remote-ssh-edit";
  # }

  # {
  #   name = "ms-vscode-remote";
  #   publisher = "remote-ssh";
  # }

  # {
  #   name = "ms-vscode-remote";
  #   publisher = "remote-containers";
  # }

  #   {
  #   name = "GitHub";
  #   publisher = "github-vscode-theme";
  # }

  # {
  #   name = "tinkertrain";
  #   publisher = "theme-panda";
  # }

  # {
  #   name = "GitHub";
  #   publisher = "copilot";
  # }

  # {
  #   name = "GitHub";
  #   publisher = "copilot-chat";
  # }

  # {
  #   name = "wayou";
  #   publisher = "vscode-todo-highlight";
  # }
]
