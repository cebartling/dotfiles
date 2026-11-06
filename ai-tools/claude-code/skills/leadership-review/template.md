# Report template

Literal skeleton for `SKILL.md` Step 5. `{…}` are placeholders; lines starting `<!--` are
instructions and are not written to the report. Omit any callout or section that would be empty.

````markdown
---
title: LTSPAY Progress Review - {Month D, YYYY}
date: {YYYY-MM-DD}
tags:
  - leadership-review
  - ltspay
  - jira
source: https://ltt.atlassian.net/jira/software/c/projects/LTSPAY/boards/1333
status: draft
---

> [!summary] Snapshot
> Pulled from the LTSPAY Jira board on {Weekday, Month D, YYYY}, covering {Month D} through {Month D}. {N} epics closed, {N} are In Progress, and {N} To Do epics show activity. {N} stories and tasks were completed. {Two or three most notable movements.}

> [!note] Status changes since the {Month D} review
> - {Epic link} ({title}): {from} → {to}.
> - New epics: {Epic link} ({title}), …
> - {Epic link} renamed from "{old title}".
> - {Epic link} ({title}) dropped off this report: {reason}.

## Closed this period

> [!success] {Epic title} ([LTSPAY-###](https://ltt.atlassian.net/browse/LTSPAY-###)) — closed {Month D}
> {One sentence on what the epic delivered.}
> - [LTSPAY-###](…) {plain-language description} — {Assignee}
> - [LTSPAY-###](…), [LTSPAY-###](…) {collapsed near-identical items} — {Assignee}
>
> **Team:** {Name}, {Name}

## In Progress

### {Epic title} ([LTSPAY-###](https://ltt.atlassian.net/browse/LTSPAY-###))

**Team:** {Name}, {Name}

> [!success] Completed
> - [LTSPAY-###](…) {description} — {Assignee}

> [!tip] Moved forward
> - [LTSPAY-###](…) {description} → {Current Status} — {Assignee}

> [!info] In progress
> - [LTSPAY-###](…) {description} ({Current Status}) — {Assignee}

> [!warning] Blocked / On Hold
> - [LTSPAY-###](…) {description} — {Assignee}

> [!failure] Rejected
> - [LTSPAY-###](…) {description} — {Assignee}

> [!todo] Queued
> - [LTSPAY-###](…) {description} ({Current Status}) — {Assignee}

<!-- Story with rolled-up sub-tasks, inside whichever callout the story belongs to: -->
<!-- > - [LTSPAY-###](…) {description} → In Progress — {Assignee}. Sub-tasks: 3 closed, 1 in progress, 23 queued. -->

### {Epic with no children} ([LTSPAY-###](…))

> [!warning] No child issues returned
> No open stories or tasks sit under this epic, and none closed in this window, so its progress can't be confirmed from Jira.

## To Do with recent activity

<!-- Same per-epic structure as In Progress. -->

> [!info] Data notes
> - Covers {since} through {report date}, inclusive. "Moved forward" means the item changed status in that window; the arrow shows where it is now, not where it started.
> - Developers are the current Jira assignee. Stories often get reassigned to QA at close, so a completed item may name the tester rather than the developer.
> - Sub-tasks are rolled up onto their parent story, not listed individually.
> - On Hold epics: {Epic link} ({title}) — {one line}; …
> - Work outside an epic: [LTSPAY-###](…) {description} ({Status}) — {Assignee}; …
> - To Do epics with no child activity in the window are omitted.

Sources: [LTSPAY board](https://ltt.atlassian.net/jira/software/c/projects/LTSPAY/boards/1333)
````
