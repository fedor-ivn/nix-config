[
  {
    key = "";
    command = "workbench.action.terminal.new";
    when = "";
  }
  {
    key = "alt+cmd+right";
    command = "workbench.action.nextEditor";
    when = "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported";
  }
  {
    key = "alt+cmd+left";
    command = "workbench.action.previousEditor";
    when = "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported";
  }
  {
    key = "ctrl+shift+`";
    command = "workbench.action.createTerminalEditor";
    when = "terminalProcessSupported || terminalWebExtensionContributedProfile";
  }
  {
    key = "cmd+k cmd+a";
    command = "workbench.action.chat.attachSelection";
    when = "editorTextFocus && editorHasSelection";
  }
]
