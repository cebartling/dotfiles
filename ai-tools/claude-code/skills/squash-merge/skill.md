---
name: squash-merge
description: Squash-merge a GitHub PR after verifying all checks have passed. Use when the user asks to "squash merge", "merge PR", invokes /squash-merge, or wants to merge a pull request with a clean single-commit history.
tools: Bash
---

# squash-merge

Squash-merge a GitHub PR after confirming all CI checks have passed.

## Workflow

### 1. Identify the PR

- If the user provided a PR number or URL, use it.
- Otherwise, detect the current branch and find its open PR:

```bash
gh pr view --json number,url,headRefName,title,state
```

- If no PR is found, stop and tell the user.
- If the PR is already merged or closed, stop and tell the user.

### 2. Verify checks

Fetch the status of all checks on the PR:

```bash
gh pr checks <pr_number>
```

Evaluate the results:
- **All checks pass**: proceed to merge.
- **Any check is failing**: stop and report which checks failed. Do NOT merge. Ask the user how they want to proceed.
- **Checks still pending/in-progress**: stop and tell the user. Offer to wait or let them re-invoke later.
- **No checks configured**: note this to the user and ask for confirmation before merging.

### 3. Confirm with the user

Before merging, show:
- PR number and title
- Branch being merged and target base branch
- Check status summary (all green / no checks)
- Number of commits that will be squashed

Ask the user to confirm the merge. Do NOT merge without explicit approval.

### 4. Squash merge

```bash
gh pr merge <pr_number> --squash --delete-branch
```

- Always use `--squash` to collapse into a single commit.
- Use `--delete-branch` to clean up the feature branch after merge.
- Do NOT use `--admin` to bypass branch protection rules.
- If the merge fails (conflicts, protection rules, etc.), report the error and stop.

### 5. Update local repo

After a successful merge, update the local working copy:

```bash
git checkout main && git pull
```

Use the actual base branch name if it differs from `main`.

### 6. Report

Tell the user:
- The merge commit SHA
- The PR that was merged (number + title)
- That the remote branch was deleted
- The current local branch and its state

Keep the report to 3–4 lines.

## Guardrails

- Never merge without explicit user confirmation.
- Never merge if any check is failing — report and stop.
- Never use `--admin` to bypass branch protection.
- Never force-merge or skip required reviews.
- Always use `--squash` — this skill does not support regular or rebase merges.
- Always delete the remote branch after merge via `--delete-branch`.
- If the PR has merge conflicts, report them and stop — do not attempt to resolve conflicts in this skill.
