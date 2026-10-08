#!/usr/bin/env bash
# PreToolUse hook for ExitPlanMode: after /linear-issue, deny plan approval until the plan
# has been posted to the Linear issue as a comment (linear-cli comments create, or the Linear
# MCP save_comment tool). Sessions that never ran /linear-issue are not affected.
set -euo pipefail

transcript=$(jq -r '.transcript_path // empty')
[[ -n "$transcript" && -f "$transcript" ]] || exit 0

# Index of the last /linear-issue run, and of the last plan comment posted after it
read -r skill_at comment_at < <(jq -rn '
  def tool_uses: .message.content | if type == "array" then .[] | select(.type == "tool_use") else empty end;
  def ran_skill:
    (.message.content | type == "string" and contains("<command-name>/linear-issue</command-name>"))
    or any(tool_uses; .name == "Skill" and .input.skill == "linear-issue");
  def posted_comment:
    any(tool_uses;
      (.name == "Bash" and (.input.command // "" | test("(^|[;&|(]\\s*)(rtk\\s+)?linear-cli\\s+comments\\s+create")))
      or (.name | test("save_comment$")));
  def last_key(f): (map(select(.value | f)) | last | .key) // -1;

  [inputs] | to_entries | map(select(.value.type == "user" or .value.type == "assistant"))
  | "\(last_key(ran_skill)) \(last_key(posted_comment))"
' "$transcript")

if (( skill_at >= 0 && comment_at < skill_at )); then
  jq -n '{hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Post the plan to the Linear issue as a comment before asking for approval (standing instruction for /linear-issue). Run: linear-cli comments create <ID> --body \"$(cat <plan file>)\", then call ExitPlanMode again."
  }}'
fi
