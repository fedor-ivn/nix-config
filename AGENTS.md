# CLAUDE.md

Claude-Code-specific. Project context lives in `openspec/config.yaml`
(`context:` block) — read that for architecture and conventions.

## Claude Code notes

- **Disable RTK temporarily** — set `RTK_DISABLED=1` to bypass PreToolUse
  rewrite when debugging weird tool output or RTK miscompression.
