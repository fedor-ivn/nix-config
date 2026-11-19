{ config, flake, ... }:
let
  # Metadata is copied from pi's bundled catalog: a models.json entry defines a
  # new model and inherits nothing from the built-in Anthropic model of the same
  # family, so without it pi would assume 128k context and 16k output.
  anthropicModel = {
    reasoning = true;
    input = [ "text" "image" ];
    promptCache = { short = 300; long = 3600; };
  };

  opusCompat = {
    supportsMidConvoEffort = true;
    supportsMidConvoSystemMessages = true;
    supportsMidConvoToolChanges = true;
    forceAdaptiveThinking = true;
    supportsTemperature = false;
    supportsStrictTools = true;
  };

  # The proxy only serves `anthropic/`-prefixed ids.
  proxyModels = [
    (anthropicModel // {
      id = "anthropic/claude-opus-5";
      name = "Claude Opus 5 (llm-proxy)";
      contextWindow = 1000000;
      maxTokens = 128000;
      cost = { input = 5; output = 25; cacheRead = 0.5; cacheWrite = 6.25; };
      thinkingLevelMap = { xhigh = "xhigh"; max = "max"; };
      compat = opusCompat;
    })
    (anthropicModel // {
      id = "anthropic/claude-opus-5-5";
      name = "Claude Opus 5.5 (llm-proxy)";
      contextWindow = 1000000;
      maxTokens = 128000;
      cost = { input = 4; output = 20; cacheRead = 0.2; cacheWrite = 5; };
      thinkingLevelMap = {
        off = null;
        minimal = null;
        low = "low";
        medium = "medium";
        high = "high";
        xhigh = "xhigh";
        max = "max";
      };
      compat = opusCompat;
    })
    (anthropicModel // {
      id = "anthropic/claude-haiku-4-5-20251001";
      name = "Claude Haiku 4.5 (llm-proxy)";
      contextWindow = 200000;
      maxTokens = 64000;
      cost = { input = 1; output = 5; cacheRead = 0.1; cacheWrite = 1.25; };
      compat.supportsStrictTools = true;
    })
  ];
in
{
  imports = [ flake.inputs.pi.homeModules.default ];

  sops.secrets."pclaude/anthropic-auth-token" = { };
  sops.secrets."pclaude/anthropic-base-url" = { };

  # The endpoint's chain roots at the corp CA, which node doesn't trust on its
  # own; `certs/tinkoff-root-ca.pem` plus NODE_EXTRA_CA_CERTS covers that for
  # every node tool (modules/darwin/system.nix).
  #
  # pi has no ANTHROPIC_BASE_URL equivalent: a custom endpoint is a models.json
  # provider. Giving the proxy an id of its own, instead of repointing the
  # built-in `anthropic` provider, leaves the stock Claude models aimed at
  # api.anthropic.com — so a personal `/login` stays possible beside it.
  #
  # `apiKey` takes `$VAR` or `!command`, but `baseUrl` is literal, hence a sops
  # template rather than a store path.
  sops.templates."pi-models.json" = {
    mode = "0600";
    content = builtins.toJSON {
      "$schema" = "https://pi.dev/schemas/models.schema.json";
      providers.llm-proxy = {
        baseUrl = config.sops.placeholder."pclaude/anthropic-base-url";
        api = "anthropic-messages";
        # Read per request, so the token stays out of pi's environment and out
        # of every command its bash tool spawns.
        apiKey = "!cat ${config.sops.secrets."pclaude/anthropic-auth-token".path}";
        authHeader = true;
        models = proxyModels;
      };
    };
  };

  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink
      config.sops.templates."pi-models.json".path;

  programs.pi.coding-agent = {
    enable = true;
    skills = builtins.attrValues config.me.ai.skills;
  };
}
