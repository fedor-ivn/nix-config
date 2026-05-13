{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "rtk-rewrite-hook";
  runtimeInputs = [ pkgs.rtk pkgs.jq ];
  text = ''
    input=$(cat)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
    [ -z "$cmd" ] && exit 0

    rewritten=$(rtk rewrite "$cmd" 2>/dev/null) || exit 0
    [ "$rewritten" = "$cmd" ] && exit 0

    jq -n --arg c "$rewritten" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        permissionDecisionReason: "RTK auto-rewrite",
        updatedInput: { command: $c }
      }
    }'
  '';
}
