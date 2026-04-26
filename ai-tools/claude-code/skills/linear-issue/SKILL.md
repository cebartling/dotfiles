---
name: linear-issue
description: Pull a Linear issue by ID (e.g. `PIN-18`) via `linear-cli`, then enter plan mode and build a plan of action grounded in the issue's contents. Use when the user invokes /linear-issue, asks to "plan this Linear issue", or hands you a Linear issue identifier and wants to scope the work before coding.
tools: Bash, Read, Grep, Glob
---

# linear-issue

Turn a Linear issue into a concrete plan of action.

## Required argument

A single Linear issue identifier, e.g. `PIN-18`, `ENG-204`. If the user
did not supply one, stop and ask for it — do not guess and do not look
it up from the current git branch unless the user asked for that.

## Workflow

### 1. Fetch the issue

Run `linear-cli` to pull the issue, including comments, in JSON for a
clean machine-readable payload:

```bash
linear-cli issues get <ID> --comments --output json
```

If the command fails:

- `not authenticated` / auth errors → tell the user to run
  `linear-cli auth` and stop. Do not try to recover.
- `issue not found` / 404-style errors → confirm the ID with the user
  and stop.
- network/timeout → report the error verbatim and stop.

If `--comments` is rejected by the installed `linear-cli` version, fall
back to `linear-cli issues get <ID> --output json` and additionally run
`linear-cli comments list <ID> --output json`.

### 2. Read the issue as context

Extract from the JSON:

- title, identifier, state, priority, assignee, team
- description (the body of the issue — this is the primary source of
  intent)
- labels (often encode area/type, e.g. `bug`, `frontend`)
- comments, in chronological order — these often contain the most
  recent decisions and override the original description
- linked/related issues, parent issue, and project (if present) — note
  the IDs but do NOT fetch them automatically. Surface them so the
  user can ask you to pull more context if relevant.

Treat later comments as more authoritative than the original
description when they conflict. If the issue is already in a
terminal state (Done, Canceled), surface that and ask the user
whether they still want to plan against it before continuing.

### 3. Ground the plan in the codebase

Before drafting the plan, do a *light* pass over the repo to anchor
the plan in real files — not an exhaustive exploration:

- Identify directories or modules the issue references by name.
- Grep for any function/component/identifier the issue calls out.
- Note the project's test framework and build commands so the plan's
  verification steps match reality (look for `package.json`,
  `Cargo.toml`, `pyproject.toml`, `Makefile`, etc.).

Skip this step entirely if the issue is purely a discussion/decision
ticket with no code component.

### 4. Enter plan mode

Use the `EnterPlanMode` tool. Everything from this point forward is a
proposed plan, not execution. Do NOT edit files or run mutating
commands while in plan mode.

### 5. Present the plan

Inside plan mode, write a plan that contains, in order:

1. **Issue summary** — one to three sentences, in your own words, of
   what the issue is asking for. Cite the issue ID and title.
2. **Acceptance criteria** — bulleted, drawn from the issue (and
   comments). If the issue does not state them explicitly, infer them
   and mark them as `(inferred)` so the user can correct.
3. **Approach** — the strategy in 2–5 sentences. Call out the main
   tradeoff or the key decision the user will need to weigh in on.
4. **Step-by-step plan** — ordered, concrete steps. Each step names
   the files or modules it will touch (use `path:line` when you
   already know the line). Include verification steps (tests, type
   checks, manual smoke test) as their own numbered items.
5. **Open questions** — anything you could not determine from the
   issue, comments, or a light code pass. Phrase each as a direct
   question. If there are no open questions, omit this section
   rather than padding it.
6. **Out of scope** — what you are deliberately *not* doing, so the
   diff stays focused. Pull from the issue's stated non-goals when
   present.

### 6. Ask for clarification when warranted

If the issue is ambiguous, contradictory, or missing critical detail,
ask the user the open questions directly *before* presenting the full
plan — a plan built on the wrong premise wastes the user's review
time. One round of clarifying questions is usually enough; do not
interrogate.

If the issue is clear, present the plan and let the user respond.

### 7. Hand off

Exit plan mode only when the user approves. Once approved, follow
the project's task-tracking convention (e.g. `bd create` for repos
that use beads) to file a tracking issue *before* writing code, if
one does not already exist.

## Guardrails

- Do not modify the Linear issue (no comments, no status changes, no
  assignment) as part of this skill. This skill is read-only against
  Linear.
- Do not edit files or run build/test commands during plan mode. The
  light codebase pass in step 3 is read-only (`grep`, `find`,
  `Read`).
- Do not invent acceptance criteria as if they came from the issue —
  inferred items must be marked `(inferred)`.
- Do not silently swallow `linear-cli` errors. If the fetch fails,
  stop and report.
- Do not chase linked/parent issues automatically; surface their IDs
  and let the user direct further fetches.
