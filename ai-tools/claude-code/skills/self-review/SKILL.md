---
name: self-review
description: Delegate a code review of the current feature branch (or the entire repository when invoked with `all`) to a stronger/different model, then walk the user through each finding to resolve (with a per-finding commit) or reject (recorded in .self-review-decisions.md so future reviews skip it). Use when the user asks to "self review", "review my branch", "review the whole repo", invokes /self-review or /self-review all, or wants a second-opinion review before pushing or opening a PR.
tools: Bash, Read, Edit, Write, Grep, Glob, Agent, AskUserQuestion
---

# self-review

Get a fresh, independent code review from a model the user chooses (typically a stronger one than the parent), then work through each finding interactively.

Two modes:

- **Branch mode (default)** — review only what's changed on the current feature branch vs. its base. This is the right mode when preparing a PR.
- **Full-repo mode** — invoked when the user passes the literal argument `all` (e.g. `/self-review all`). Reviews the entire committed codebase, not a diff. Use this for periodic codebase health checks, onboarding audits, or before a major release.

Throughout the workflow, treat `all` mode as the variation; everything else is the default branch-mode behavior unless noted.

## Workflow

### 0. Parse the argument

The skill accepts a single optional argument:

- *(no argument)* — branch mode (default).
- `all` — full-repo mode.

Anything else: surface the unknown argument to the user, ask whether they meant `all` or no argument, and wait for confirmation before continuing. Do not silently fall back.

Set an internal `mode` variable to `branch` or `all` and reference it throughout the rest of the workflow.

### 1. Verify repo state

Run in parallel:

- `git rev-parse --is-inside-work-tree` — confirm we're in a git repo. If not, stop.
- `git branch --show-current` — current branch.
- `git status --porcelain` — flag uncommitted changes; the review covers committed changes only, so warn the user if the working tree is dirty and ask whether to proceed anyway.
- **Branch mode only:** detect the base branch — prefer `main`, fall back to `master`. Confirm it exists locally with `git rev-parse --verify <base>`. If both are missing, ask the user which branch to diff against.

**Branch mode only:** if the current branch *is* the base branch (e.g., `main`), stop — there is nothing to review. (In `all` mode this check does not apply: full-repo review is valid on any branch, including `main`.)

### 2. Prompt the user for the review model

Use `AskUserQuestion` to ask which model should perform the review. Recommend a model **stronger than or different from** the model currently driving the conversation, so the review brings an independent perspective.

Options to offer (one question, single-select):

- `opus` — most capable Claude model; recommended default
- `sonnet` — balanced; faster than Opus, still strong
- `haiku` — fastest; use only for small or low-risk diffs

Surface the chosen value as `reviewModel` and pass it as the `model` parameter when launching the Agent in step 4.

### 3. Gather the review material and decision log

**Branch mode**, in parallel:

- `git fetch origin <base> --quiet` (best-effort; ignore failure if offline).
- `git diff <base>...HEAD --stat` — high-level summary.
- `git diff <base>...HEAD` — full patch. If this is very large (>4000 lines), tell the user and ask whether to proceed (the review may sample rather than cover everything).
- `git log <base>..HEAD --oneline` — commit list on the branch.

**Full-repo mode (`all`)**, in parallel:

- `git ls-files | wc -l` and `git ls-files` — total tracked file count and the file list. If the repo is very large (>2000 files or >200k lines), warn the user and ask whether to proceed; the review agent will need to sample rather than read everything.
- A language/structure overview: top-level directories (`ls -1`), and a per-extension count (e.g. `git ls-files | sed -n 's/.*\.//p' | sort | uniq -c | sort -rn | head -20`).
- `git log -1 --format='%h %s'` — the tip commit, so the agent can reference repo state.
- Read `README.md` and any top-level `CLAUDE.md` so the agent understands what the project *is* before critiquing it.

**Both modes:** read `.self-review-decisions.md` from the repo root if it exists. This is the running log of previously-rejected findings; the review agent must read it and skip anything already rejected for the same reason.

### 4. Delegate the review to a sub-agent

Launch a single `Agent` (subagent_type `general-purpose`) with `model: <reviewModel>` from step 2. The prompt must be self-contained — the sub-agent has no memory of this conversation.

Brief the agent with:

- The mode (branch or full-repo) and that this is a self-review (not an external PR review).
- **Branch mode:** the branch name, base branch, the full diff (or a pointer to run the same `git diff` itself), the list of files changed, and the commit list.
- **Full-repo mode:** the repo root path, the file list / language overview, the tip commit, and explicit instructions to read source files itself with `Read`/`Grep`/`Glob` rather than receiving a diff. Tell it to prioritize: correctness and security across hot paths, architectural smells, dead code, missing tests, drifted docs, and broad conventions violations. Cap the finding count at ~30 unless the agent thinks more are critical — full-repo reviews can otherwise produce overwhelming lists.
- The contents of `.self-review-decisions.md` if it exists, with explicit instructions: *do not re-flag any issue that already appears in this file with the same file:line and rationale*.
- Any project conventions worth checking (read `CLAUDE.md` and any nested CLAUDE.md files — in branch mode focus on changed directories; in `all` mode read all of them).
- The expected output format (see below).

Ask for **structured findings** in JSON inside fenced markdown so we can parse them, e.g.:

````
```json
[
  {
    "id": 1,
    "severity": "high|medium|low",
    "category": "correctness|security|performance|maintainability|style|tests|docs",
    "file": "path/relative/to/repo.js",
    "line": 42,
    "title": "One-line summary",
    "rationale": "Why this matters in 1–3 sentences",
    "suggestion": "Concrete proposed fix — code snippet or steps"
  }
]
```
````

Also ask for a short prose summary above the JSON (overall impression, top concerns), and a "no issues found" empty array if the diff is clean.

### 5. Present findings to the user

Parse the JSON and print a compact table:

```
## Self-review findings (model: <reviewModel>)

| #  | Severity | File:line          | Title                       |
|----|----------|--------------------|-----------------------------|
| 1  | high     | routes/foo.js:42   | Missing input validation    |
| 2  | medium   | helpers/bar.js:10  | Off-by-one in loop bound    |
```

Below the table, print the agent's prose summary verbatim.

If there are zero findings, congratulate the user and stop.

### 6. Walk findings interactively

For each finding, in order:

1. Print finding `#N` with full details: severity, file:line, title, rationale, suggestion.
2. Read the file around the cited line (±10 lines) so the user has context inline.
3. Use `AskUserQuestion` with options:
   - **Resolve** — apply the suggested fix (or your judgment-call equivalent if the suggestion is incomplete)
   - **Reject** — keep as-is; record the decision so future reviews skip it
   - **Skip** — defer for now (no commit, no decision-log entry)

Do not auto-resolve. Each finding requires explicit user confirmation.

### 7. Apply resolutions

When the user picks **Resolve**:

1. Make the code change(s) using `Edit` (or `Write` for new files). Keep changes minimal and scoped to the finding — do not refactor surrounding code.
2. Run any obvious smoke check that's cheap and relevant (linter, the targeted Jest test for the touched file, etc.). If it fails, fix and retry; do not commit broken code.
3. Stage **only** the affected files by path. Never `git add -A` / `git add .`.
4. Commit using HEREDOC with a per-finding message:

   ```bash
   git commit -m "$(cat <<'EOF'
   self-review: <short title from the finding>

   <one or two sentences on what changed and why — derived from the rationale>

   Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```

5. Capture the commit SHA for the final report.

Never use `--no-verify`, `--amend`, or `--no-gpg-sign`. If a pre-commit hook fails: fix the underlying issue, re-stage, and create a new commit.

### 8. Apply rejections

When the user picks **Reject**:

1. Ask the user (free-text via `AskUserQuestion` if helpful, or a quick inline prompt) for a one-line reason. If they don't supply one, default to "intentional".
2. Append an entry to `.self-review-decisions.md` at the repo root, creating the file if missing. Format:

   ```markdown
   ## YYYY-MM-DD <branch> (<mode>)

   - **<file>:<line>** — <finding title>
     - **Severity:** <severity>
     - **Reason for rejection:** <user reason>
     - **Reviewed by:** <reviewModel>
   ```

   `<mode>` is `branch` or `all`, so future reviews can tell which kind of pass produced the rejection.

3. Do **not** modify any source file. The decision log is the only record.
4. Do not commit yet — rejections are batched into a single commit at the end (step 9).

### 9. Finalize

After all findings have been processed:

- If `.self-review-decisions.md` was modified, stage it and commit:

  ```bash
  git add .self-review-decisions.md
  git commit -m "$(cat <<'EOF'
  chore: record self-review decisions

  Captures rejections from the <mode> self-review pass on <branch>
  so future reviews don't re-flag the same items.

  Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
  EOF
  )"
  ```

  Substitute `<mode>` with `branch` or `full-repo` and `<branch>` with the current branch name.

- Print a summary table:

  ```
  ## Self-review summary

  | #  | File:line         | Decision  | Commit   |
  |----|-------------------|-----------|----------|
  | 1  | routes/foo.js:42  | Resolved  | abc1234  |
  | 2  | helpers/bar.js:10 | Rejected  | —        |
  | 3  | helpers/baz.js:7  | Skipped   | —        |

  Resolved: 1 | Rejected: 1 | Skipped: 1 | Total: 3
  Decisions recorded in .self-review-decisions.md
  ```

- Do **not** push automatically. Tell the user the branch has new local commits and suggest `git push` (or `/stage-commit-push`) when they're ready.

## Guardrails

- The review agent runs in isolation (no shared context with this conversation). The prompt must include everything it needs.
- Always require explicit user approval per finding — never auto-resolve.
- One commit per resolved finding; one batched commit for the rejection log. Do not amend.
- Never force-push. This skill never pushes — surface that to the user and let them choose when.
- Stage only the files relevant to each finding. Never `git add -A` / `git add .`.
- Never use `--no-verify`, `--amend`, or `--no-gpg-sign`.
- If a finding is unclear, ambiguous, or scopes outside this branch, surface it to the user instead of guessing.
- The skill is non-destructive: rejections only append to a markdown log; no source files are modified for a rejection.

## Edge cases

**Working tree dirty before starting:** Warn and ask whether to (a) stash, (b) commit first, or (c) proceed reviewing committed changes only and ignore the dirty files. Do not stash without confirmation.

**Branch already in sync with base (no commits ahead):** In branch mode, stop and tell the user there is nothing to review — and suggest `/self-review all` if they wanted a full-repo pass instead. In `all` mode, this check does not apply.

**Empty repo (no commits) in `all` mode:** Stop — there is nothing to review.

**Sub-agent returns malformed JSON:** Ask it once to reformat. If it still fails, fall back to presenting the prose findings and walk through them manually with the user, asking them to identify each one.

**`.self-review-decisions.md` exists in `.gitignore`:** Surface to the user — they may want it committed; do not modify `.gitignore` automatically.

**Pre-commit hook reformats the file (prettier, etc.):** That's expected. Re-stage and commit again. Never use `--no-verify`.
