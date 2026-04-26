---
name: stage-commit-push
description: Stage untracked files created in this session, commit changes, and push to the GitHub remote origin. Use when the user asks to "stage commit and push", invokes /stage-commit-push, or wants a one-shot ship of the current session's work.
tools: Bash
---

# stage-commit-push

Ship the current session's work in one go: stage new files, create a commit, push to `origin`.

## Workflow

### 1. Inspect repo state

Run these in parallel:

- `git status` (no `-uall`) — see modified and untracked files
- `git diff` — staged and unstaged changes
- `git diff --staged` — anything already staged
- `git log -10 --oneline` — match the repo's commit message style
- `git branch --show-current` and `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null` — current branch and upstream (if any)

### 2. Stage files

Stage **only** the files created or modified during the current session. Cross-reference `git status` against the files you actually touched in this conversation — do not blindly stage everything.

- Add files individually by path. Do NOT use `git add -A` or `git add .` — those can sweep in unrelated work or secrets.
- Skip anything that looks like a secret (`.env`, `credentials.json`, key files, tokens). If a session-created file looks sensitive, stop and ask the user before staging.
- If there is nothing session-related to stage and nothing already staged, stop and tell the user there is nothing to commit.

### 3. Commit

- Write a concise message that reflects the *why* of the change, in the style of recent commits in `git log`.
- Pass the message via HEREDOC and include the Claude co-author trailer:

```bash
git commit -m "$(cat <<'EOF'
<subject line>

<optional body>

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

- Never use `--no-verify`, `--amend`, or `--no-gpg-sign`.
- If a pre-commit hook fails: fix the underlying issue, re-stage, and create a NEW commit. Do not amend.

### 4. Push to origin

- If the current branch has an upstream: `git push`.
- If it does not: `git push -u origin <branch>`.
- Never force-push. If a non-fast-forward error occurs, stop and report it to the user — do not `--force` or `--force-with-lease` without explicit approval.
- Never push to `main`/`master` with `--force` under any circumstance.

### 5. Report

Tell the user:

- The commit SHA and subject line
- The branch and remote it was pushed to
- The PR URL if `git push` printed one

Keep the report to 2–3 lines.

## Guardrails

- Only commit when the user explicitly invokes this skill — do not run it proactively.
- Do not stage files outside the current session's work, even if `git status` shows them as dirty. If unsure whether a file belongs to this session, ask.
- Do not modify `.gitignore`, git config, or hooks as part of this skill.
