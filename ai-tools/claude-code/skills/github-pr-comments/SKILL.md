---
name: github-pr-comments
description: Retrieve GitHub PR review comments, iterate through each one resolving or rejecting it, commit fixes individually, and resolve comment threads via the GraphQL API. Use when the user asks to "address PR comments", "resolve PR feedback", invokes /github-pr-comments, or wants to work through review comments on a pull request.
tools: Bash, Read, Edit, Write, Grep, Glob, Agent
---

# github-pr-comments

Work through all review comments on a GitHub PR: resolve or reject each one, commit fixes individually, and mark threads as resolved.

## Workflow

### 1. Identify the PR

- If the user provided a PR number or URL, use it.
- Otherwise, detect the current branch and find its open PR:

```bash
gh pr view --json number,url,headRefName
```

- If no PR is found, stop and tell the user.

### 2. Fetch review comments

Retrieve all review comments (not issue-level comments) for the PR:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews --paginate
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate
```

Parse out each comment thread. For each comment, capture:
- `id` (REST API id)
- `node_id` (GraphQL node ID, needed to resolve threads)
- `path` (file path)
- `line` / `original_line` (line number in the diff)
- `body` (the reviewer's comment text)
- `in_reply_to_id` (to group threads — only process root comments, skip replies)
- `user.login` (who left the comment)

Group replies under their root comment to form threads. Only act on root comments (where `in_reply_to_id` is null/absent).

### 3. Iterate through each comment

For each root comment thread, present the comment to the user with context:

1. Show the file path, line number, reviewer, and comment body.
2. Read the relevant file and surrounding lines so you understand the context.
3. Propose a resolution: explain what change you would make and why.
4. **Ask the user** whether to:
   - **Resolve** — apply the fix
   - **Reject** — skip this comment (optionally note why)
   - **Custom** — the user provides an alternative approach

Do NOT auto-resolve comments without user approval. Each comment requires explicit confirmation.

### 4. Apply and commit (for resolved comments)

When the user approves a resolution:

1. Make the code change.
2. Stage only the affected file(s) by path — never `git add -A` or `git add .`.
3. Commit with a message referencing the PR comment:

```bash
git commit -m "$(cat <<'EOF'
<concise description of the fix>

Resolves PR #<number> review comment by @<reviewer>

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

4. Record the commit SHA and the comment summary for the final report.

- Never use `--no-verify`, `--amend`, or `--no-gpg-sign`.
- If a pre-commit hook fails: fix the issue, re-stage, and create a NEW commit.

### 5. Resolve the thread on GitHub

After committing a fix, resolve the comment thread using the GitHub GraphQL API. Use the `node_id` from the comment to find its thread, then resolve it:

```bash
gh api graphql -f query='
  query($nodeId: ID!) {
    node(id: $nodeId) {
      ... on PullRequestReviewComment {
        pullRequestReview {
          id
        }
      }
    }
  }
' -f nodeId="<comment_node_id>"
```

Then resolve the thread:

```bash
gh api graphql -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: {threadId: $threadId}) {
      thread {
        isResolved
      }
    }
  }
' -f threadId="<thread_node_id>"
```

To get the thread ID from a comment node ID:

```bash
gh api graphql -f query='
  query($nodeId: ID!) {
    node(id: $nodeId) {
      ... on PullRequestReviewComment {
        id
        body
        pullRequestThread: replyTo {
          id
        }
      }
    }
  }
' -f nodeId="<comment_node_id>"
```

If the above does not return the thread ID directly, use the PR's review threads query:

```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            comments(first: 1) {
              nodes {
                id
                body
              }
            }
          }
        }
      }
    }
  }
' -f owner="<owner>" -f repo="<repo>" -F pr=<number>
```

Match the thread by its first comment's body or ID, then resolve it with the mutation above.

### 6. Push all commits

After all comments have been processed:

- If the branch has an upstream: `git push`.
- If not: `git push -u origin <branch>`.
- Never force-push.

### 7. Print summary

Print a table summarizing all comments:

```
## PR Comment Resolution Summary

| # | File | Reviewer | Status | Commit |
|---|------|----------|--------|--------|
| 1 | src/foo.ts:42 | @reviewer | Resolved | abc1234 |
| 2 | src/bar.ts:10 | @reviewer | Rejected — intentional design | — |
| 3 | src/baz.ts:7  | @reviewer | Resolved | def5678 |

Resolved: 2 | Rejected: 1 | Total: 3
```

Include:
- File path and line
- Reviewer username
- Status (Resolved or Rejected with brief reason)
- Commit SHA (for resolved) or `—` (for rejected)
- Totals at the bottom

## Guardrails

- Always ask the user before resolving or rejecting each comment — never auto-resolve.
- Stage only files related to the specific comment being addressed.
- One commit per resolved comment — do not batch fixes.
- Never force-push. If push fails, report the error and stop.
- Never use `--no-verify`, `--amend`, or `--no-gpg-sign`.
- If a comment is unclear or ambiguous, ask the user for clarification rather than guessing.
- If a comment requires changes outside the scope of the PR, flag it to the user rather than making sweeping changes.
