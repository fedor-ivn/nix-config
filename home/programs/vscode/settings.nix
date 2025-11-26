{
  "[dockercompose]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };
  "[haskell]" = {
    "editor.rulers" = [ 80 ];
    "editor.suggestSelection" = "recentlyUsedByPrefix";
  };
  "[html]" = {
    "editor.defaultFormatter" = "vscode.html-language-features";
  };
  "[javascript]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };
  "[json]" = {
    "editor.defaultFormatter" = "vscode.json-language-features";
  };
  "[latex]" = {
    "editor.formatOnPaste" = false;
    "editor.rulers" = [
      80
      100
    ];
    "editor.suggestSelection" = "recentlyUsedByPrefix";
  };
  "[markdown]" = {
    "editor.quickSuggestions" = {
      comments = "off";
      other = "off";
      strings = "off";
    };
    "editor.rulers" = [
      80
      100
    ];
    "editor.wordWrap" = "on";
  };
  "[scala]" = {
    "editor.rulers" = [
      80
      120
    ];
  };
  "[typst]" = {
    "editor.rulers" = [
      80
      100
    ];
  };
  "debug.onTaskErrors" = "abort";
  "dev.containers.dockerPath" = "podman";
  # "editor.fontFamily" = "'Monaspace Neon', monospace";
  # "editor.fontLigatures" = "'calt', 'liga', 'dlig', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08'";
  "editor.fontFamily" = "'JetBrains Mono', monospace";
  # "editor.fontSize" = 12;
  "editor.fontLigatures" = true;
  "editor.inlineSuggest.enabled" = true;
  "editor.minimap.enabled" = false;
  "editor.renderWhitespace" = "boundary";
  "editor.unicodeHighlight.allowedLocales" = {
    ru = true;
  };
  "editor.inlayHints.enabled" = "offUnlessPressed";
  "explorer.confirmDragAndDrop" = false;
  "files.autoSave" = "onFocusChange";
  "files.insertFinalNewline" = true;
  "files.watcherExclude" = {
    "**/.ammonite" = true;
    "**/.bloop" = true;
    "**/.metals" = true;
  };
  "genieai.enableConversationHistory" = true;
  "git.confirmSync" = false;
  "github.copilot.enable" = {
    "*" = true;
    markdown = true;
    plaintext = false;
    scminput = false;
  };
  "notebook.cellToolbarLocation" = {
    default = "right";
    jupyter-notebook = "right";
  };
  "notebook.formatOnCellExecution" = true;
  "remote.autoForwardPortsSource" = "hybrid";
  "rewrap.autoWrap.enabled" = true;
  "security.workspace.trust.untrustedFiles" = "open";
  "terminal.integrated.defaultProfile.osx" = "zsh";
  "terminal.integrated.enableMultiLinePasteWarning" = false;
  "terminal.integrated.fontFamily" = "MesloLGS NF";
  "terminal.integrated.fontWeight" = "normal";
  "terminal.integrated.scrollback" = 10000;
  "todohighlight.defaultStyle" = { };
  "todohighlight.include" = [
    "**/*.js"
    "**/*.jsx"
    "**/*.ts"
    "**/*.tsx"
    "**/*.html"
    "**/*.php"
    "**/*.css"
    "**/*.scss"
  ];
  "todohighlight.isEnable" = true;
  "todohighlight.keywords" = [
    {
      backgroundColor = "transparent";
      color = "Khaki";
      isWholeLine = false;
      overviewRulerColor = "DarkKhaki";
      text = "TODO:";
    }
    {
      backgroundColor = "transparent";
      color = "Khaki";
      isWholeLine = false;
      overviewRulerColor = "DarkKhaki";
      text = "todo:";
    }
    {
      backgroundColor = "#72824E";
      border = "1px solid #72824E";
      borderRadius = "3px";
      color = "#000000";
      isWholeLine = false;
      overviewRulerColor = "#72824E";
      text = "note:";
    }
    {
      backgroundColor = "transparent";
      color = "pink";
      isWholeLine = false;
      overviewRulerColor = "DarkKhaki";
      text = "warn:";
    }
  ];
  "window.zoomLevel" = 1;
  "workbench.activityBar.location" = "top";
  # "workbench.colorTheme" = "Solarized Light";
  "workbench.colorTheme" = "GitHub Dark";
  "editor.accessibilitySupport" = "off";
  "accessibility.voice.speechTimeout" = 0;
  "update.mode" = "none";
}
