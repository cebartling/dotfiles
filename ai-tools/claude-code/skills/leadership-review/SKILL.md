---
name: leadership-review
description: Generate the biweekly LTSPAY leadership progress review from the Jira board (via the Atlassian MCP) into the Life Time, Inc Obsidian vault as `{NN} - {Month D, YYYY}.md`. Covers everything since the previous report — epics closed in the window, per-epic work grouped into state callouts, and the developer on every item. Use when the user asks for "the leadership review", "progress review", "LTSPAY status report", or invokes /leadership-review. Accepts an optional report date (`/leadership-review 2026-11-20`); defaults to today.
tools: Bash, Read, Write, Glob, AskUserQuestion, mcp__claude_ai_Atlassian_MCP__executeRead, mcp__claude_ai_Atlassian_MCP__searchJiraIssuesUsingJql
---

# leadership-review

Build the LTSPAY leadership progress review for the window since the last report, from live Jira
data, and write it into the vault. The report is read by leadership: plain language, every claim
traceable to a Jira key, every item naming its developer.

## Constants

| Name | Value |
|---|---|
| Project | `LTSPAY` |
| Board URL | `https://ltt.atlassian.net/jira/software/c/projects/LTSPAY/boards/1333` |
| cloudId | `ltt.atlassian.net` |
| Issue URL | `https://ltt.atlassian.net/browse/{KEY}` |
| Output dir | `~/Documents/Default/Consulting/Life Time, Inc/Leadership Progress Review/` |

The vault folder is `Life Time, Inc` — no trailing period. A same-named folder *with* a period
exists and is empty; never write there.

## Step 1 — Resolve the dates and the target file

1. **Report date** = the argument if given (`YYYY-MM-DD`), otherwise today.
2. List the output dir. Files are `{NN} - {Month} {D}, {YYYY}.md` (e.g. `07 - October 23, 2026.md`;
   day not zero-padded, `NN` zero-padded to two digits).
3. **Previous report** = the highest-`NN` file *dated before* the report date. Read it in full —
   Step 4 compares against it. **Window start (`since`)** = that file's frontmatter `date:`.
   If no previous report exists, ask the user for the window start.
4. **Target file**: if a file for the report date already exists, reuse its `NN`, show the user
   its first ~15 lines, and ask (AskUserQuestion): overwrite, write `{NN} - {Month D, YYYY}-v2.md`,
   or abort. It may contain hand edits. Otherwise `NN` = highest existing + 1.

The window is inclusive of `since` (JQL `"YYYY-MM-DD"` means midnight starting that day). Items
that closed on the previous report's date after it was pulled would otherwise be lost; the
occasional overlap is the lesser evil.

## Step 2 — Fetch from Jira

**Always query through `executeRead` with `responseFields`.** `searchJiraIssuesUsingJql` called
directly returns full avatar and nested-parent objects (~2.5 KB per issue — 160 children is
~100k tokens). Through `executeRead` with `responseFields` it is ~150 bytes per issue:

```
executeRead(
  cloudId: "ltt.atlassian.net",
  name: "searchJiraIssuesUsingJql",
  inputs: { jql: "...", fields: [...], maxResults: 100 },
  responseFields: ["issues.key", "issues.fields.summary", ..., "isLast", "nextPageToken"]
)
```

Paths are `issues.key` / `issues.fields.<x>` — **not** `issues.nodes.*` (that silently returns
empty objects). **Always include `isLast` and `nextPageToken`** and keep paging
(`inputs.nextPageToken`) until `isLast` is true — the moved-set query routinely exceeds 100.

Run these four queries (substitute `{since}`):

| # | JQL | fields / responseFields |
|---|---|---|
| Q1 epics | `project = LTSPAY AND issuetype = Epic AND (statusCategory != Done OR status CHANGED DURING ("{since}", now())) ORDER BY key` | summary, status.name, status.statusCategory.name, assignee.displayName, created, resolutiondate |
| Q2 children | `project = LTSPAY AND issuetype != Epic AND parent is not EMPTY AND (statusCategory != Done OR resolved >= "{since}") ORDER BY key` | summary, status.name, status.statusCategory.name, assignee.displayName, parent.key, resolutiondate, created |
| Q3 moved | `project = LTSPAY AND issuetype != Epic AND status CHANGED DURING ("{since}", now()) ORDER BY key` | key only |
| Q4 epics moved | `project = LTSPAY AND issuetype = Epic AND status CHANGED DURING ("{since}", now()) ORDER BY key` | key, status.name |

## Step 3 — Classify

### Resolve the hierarchy

Q2 returns stories/tasks *and* sub-tasks. For each Q2 item:

- `parent.key` is a Q1 epic → it is a **child** of that epic.
- `parent.key` is itself a child → it is a **sub-task**. Don't list it; roll it up onto its
  parent story as counts, e.g. "(sub-tasks: 3 closed, 1 in progress, 23 queued)". Omit the
  roll-up for routine QA sub-tasks ("QA Write Test Cases" / "QA Execute Tests") — they add noise.
- Anything else (parent epic not in Q1, e.g. a closed epic outside the window) → drop it.

### Bucket each child — first matching rule wins

| # | Condition | Callout |
|---|---|---|
| 1 | statusCategory Done, status `Reject`/`Rejected`, resolved ≥ since | `[!failure] Rejected` |
| 2 | statusCategory Done, resolved ≥ since | `[!success] Completed` |
| 3 | status `On Hold` or `Blocked` | `[!warning] Blocked / On Hold` |
| 4 | statusCategory In Progress, key in Q3 | `[!tip] Moved forward` — show `→ {current status}` |
| 5 | statusCategory In Progress, not in Q3 | `[!info] In progress` |
| 6 | statusCategory To Do | `[!todo] Queued` — show current status |

**Use status category, not `resolutiondate`, to decide done-ness.** Reopened items keep a stale
`resolutiondate` (seen on Dev Complete and Ready for Prod items). `resolutiondate` only dates a
Done item.

A sub-task's progress counts as activity for its epic (Step 3, epic buckets) even though the
sub-task itself isn't listed.

### Bucket each epic

| Condition | Section |
|---|---|
| statusCategory Done and resolved ≥ since | `## Closed this period` |
| status `On Hold` | Data notes callout only |
| statusCategory In Progress | `## In Progress` |
| statusCategory To Do **and** (a child or sub-task is in Q3, created ≥ since, or resolved ≥ since) | `## To Do with recent activity` |
| statusCategory To Do, epic created ≥ since, no children | Status-changes note only ("new, no child work yet") |
| statusCategory To Do, otherwise | omit |

An In Progress epic with no children gets `> [!warning] No child issues returned` instead of
state callouts — its progress can't be confirmed from Jira.

### Team line

`**Team:**` = distinct assignees across the epic's children in Completed, Rejected, Moved
forward, In progress, and Blocked (not Queued — a queued assignee isn't working it yet), plus
assignees of rolled-up sub-tasks that closed or are in progress. Alphabetical. Omit the line if
empty.

### Self-check before writing

For every epic: listed children per callout must sum to that epic's child count from Q2. Every
Q3 key whose epic is in a written section must appear somewhere (as a child, or inside a
sub-task roll-up). Fix discrepancies before writing — don't ship a report that silently drops
work.

**Q3 keys absent from Q2 have no parent** — real work done outside any epic. Fetch them in one
query (`key in (…)`, fields summary, status, assignee, issuetype) and list them in the Data
notes under "Work outside an epic", bucketed the same way (completed / in progress / …).

## Step 4 — Compare with the previous report

From the previous report (read in Step 1), note which section each epic was in and its heading
title. Then build the `Status changes since {prior date}` note from:

- **Q4 epics** — each is a real status change; phrase as `{prior section/status} → {current status}`
  using the previous report for the "from" side. If the epic wasn't in the previous report, say
  it is new or newly active.
- **Epics created ≥ since** — "New epics this period".
- **Renames** — a prior heading whose title text clearly differs from the current summary
  (not just abbreviation). Say "renamed from …".
- **Dropped out** — epics that had a section last time and don't now (no activity, or moved to
  On Hold). One line each, with the reason. Closed epics go in their own section, not here.

## Step 5 — Write the report

Follow [`template.md`](template.md) exactly for section order, frontmatter, and callout syntax.
Rules:

- **Every Jira key is a link**: `[LTSPAY-578](https://ltt.atlassian.net/browse/LTSPAY-578)`.
  Inside headings keep the link too — Obsidian renders it.
- **Every child line names its assignee** after an em dash: `— Jon Osorio`, or `— Unassigned`.
  Use the Jira display name as-is.
- **Describe the work, not the ticket.** Paraphrase summaries into plain language a director can
  read ("Restrict actuator /manage endpoints to internal access on card-security-api"), keep
  service names in backticks. Several near-identical items (batch 1-5, per-service tasks) collapse
  into one line listing all keys.
- **Omit empty callouts.** No "(none)".
- **Closed this period**: one `[!success]` callout per epic — title + link, close date,
  one line on what it delivered (from its children), the children closed in the window with
  assignees, and the team. An epic closed with no children in the window says so and names the
  epic's own assignee as `**Epic owner:**` instead of a Team line.
- **Snapshot** (`[!summary]`): 2-4 sentences — pull date, window, count of epics per section,
  count of child items completed, and the two or three most notable movements.
- **Data notes** (`[!info]`): On Hold epics with one line each, omitted-epic rule, and the
  standing caveats from the template. Add anything the self-check had to reconcile.
- Order epics within a section by most activity first (completed + moved), ties by key.
- Never put member data (names of members, card data) in the report — it is about the team's
  work. Developer names are fine.

Write the file with the Write tool, frontmatter `status: draft`. Text files end with a newline.

## Step 6 — Report back

Tell the user: the file path, epics per section, child items completed / rejected in the window,
anything the self-check reconciled, and any epic whose status you couldn't place. Don't paste
the report into the chat.
