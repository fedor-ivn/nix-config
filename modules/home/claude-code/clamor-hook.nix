{ pkgs, flake, ... }:

let
  clamor = flake.inputs.clamor.packages.${pkgs.stdenv.system}.default;
in
pkgs.writeShellApplication {
  name = "clamor-state-hook";
  runtimeInputs = [ clamor pkgs.jq ];
  text = ''
    # No-op when not spawned by clamor.
    [ -n "''${CLAMOR_AGENT_ID:-}" ] || exit 0

    input=$(cat)
    event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty')

    args=(--agent "$CLAMOR_AGENT_ID")
    case "$event" in
      UserPromptSubmit)
        state=working
        token=$(printf '%s' "$input" | jq -r '.session_id // empty')
        [ -n "$token" ] && args+=(--session-token "$token")
        ;;
      PreToolUse)
        state=working
        tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
        [ -n "$tool" ] && args+=(--tool "$tool")
        ;;
      PermissionRequest)
        state=input
        tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
        [ -n "$tool" ] && args+=(--tool "$tool")
        ;;
      PostToolUse | PreCompact)
        state=working
        ;;
      Notification | Stop)
        state=input
        ;;
      *)
        exit 0
        ;;
    esac

    clamor set-state "$state" "''${args[@]}" || exit 0
  '';
}
