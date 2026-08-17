---
name: daily-journal
description: Append a summary of the current conversation's work to the user's Obsidian daily work journal (Consulting/{Client}/Daily Journal/...), matching the file's existing dated-section conventions. Use when the user asks to "update my journal", "update the work summary in Obsidian", invokes /daily-journal, or wants today's work logged to their daily journal. Accepts an optional target-file path (e.g. `/daily-journal <path>`) that overrides the inferred client/week file.
tools: Bash, Read, Write, Glob, AskUserQuestion
---

# daily-journal

Log the current conversation's work into the user's Obsidian daily work journal, matching the
journal's existing conventions exactly, without disturbing anything already written there.

## Vault layout

```
~/Documents/Default/Consulting/{Client}/Daily Journal/{YYYY}/{MM} - {Month}/{Month} {startDay}-{endDay}, {YYYY}.md
```

- Weeks are **Monday–Sunday**, clamped to the current calendar month — a week that would otherwise
  span two months gets truncated at the month boundary (e.g. `July 27-31, 2026.md` stops at
  month-end rather than continuing into August; the next week starts fresh, e.g.
  `August 3-9, 2026.md`).
- Week files only exist when there's actual content — there is no empty placeholder file for an
  idle week or weekend. Don't be surprised by gaps in the sequence.
- Month directory names are zero-padded with a single space around the dash: `08 - August`,
  `01 - January`. (One existing directory in this vault has a stray double space —
  `02 -  February` — that's a pre-existing typo; don't replicate it in anything you create.)
- File bodies have **no frontmatter and no title line** — they start directly with the first
  `## Month Day, Year` header. Days are appended in chronological order down the file.
- **Do not confuse this with `~/Documents/Default/Daily/YYYY-MM-DD.md`** — that's the vault's
  separate built-in Obsidian daily-notes system, and inference never targets it. (An explicit
  path argument may legitimately point there; see below.)

## Optional argument

The skill accepts a single optional argument — the path of the file to write:

- *(no argument)* — **inferred mode** (default). Derive the target file from today's date and the
  client, exactly as in workflow steps 1 and 2.
- *a file path* — **explicit mode**. Use that file as the target and **skip steps 1 and 2
  entirely** — no week-window math, no client inference, no client question.

The argument chooses *which file* is written. It never changes *what* is written: steps 5–7 —
today's-section detection, synthesis, and the append-only splice — behave identically in both
modes.

### Resolving the path

- Absolute (`/…`) or `~`-prefixed → expand `~` and use as-is.
- Anything else → resolve against the **vault root** `~/Documents/Default/`, *not* the current
  working directory. So
  `Consulting/Acme/Daily Journal/2026/08 - August/August 17-23, 2026.md` works as a short form.
  Never resolve a bare relative path against the cwd — that risks writing into the project repo
  being worked on.
- Resolve symlinks and `..` segments *before* the boundary check below, so a path like
  `../../etc/foo` can't slip past a naive prefix comparison.

### Vault boundary

After resolving, the path must be inside `~/Documents/Default/`. Anywhere in the vault is fair
game — `Consulting/`, `Daily/`, anywhere else. If the resolved path falls **outside** the vault,
stop and ask the user rather than writing.

## Workflow

### 1. Compute today's date and this week's file path

*Skip this step in explicit mode — the target file is already known. You still need today's date
for the section header in step 5, so compute `today` regardless.*

```bash
today=$(date +%Y-%m-%d)
dow=$(date +%u)   # 1=Mon .. 7=Sun
monday=$(date -j -v-$((dow-1))d -f "%Y-%m-%d" "$today" +%Y-%m-%d)
sunday=$(date -j -v+$((7-dow))d -f "%Y-%m-%d" "$today" +%Y-%m-%d)
```

Clamp `monday`/`sunday` to the current calendar month: if `monday`'s month differs from today's
month, replace it with the 1st of today's month; if `sunday`'s month differs from today's month,
replace it with the last day of today's month (`date -j -v1m -v+1d -v-1d ...` or equivalent).

Build the filename `{Month} {startDay}-{endDay}, {YYYY}.md` (month name spelled out once, e.g.
`August 10-16, 2026.md`) and the directory `{YYYY}/{MM} - {Month}/` (zero-padded month number).

### 2. Infer the client

*Skip this step entirely in explicit mode — the user named the file, so there is nothing to infer
and nothing to ask about.*

The vault has one journal per client under `~/Documents/Default/Consulting/`. List them:

```bash
ls "$HOME/Documents/Default/Consulting"
```

If the current working directory is inside a git repo, gather signals:

```bash
git remote get-url origin 2>/dev/null
pwd
```

- Extract the org/owner from the remote URL (e.g. `Life-Time-Inc` from
  `git@github.com:Life-Time-Inc/chase-commerce-gateway-api.git`).
- Note the sandbox parent directory name if the path looks like `.../github-sandbox/{parent}/{repo}`
  (e.g. `lifetime`).

Normalize both the signals and each client folder name (lowercase, strip everything but
alphanumerics — so `Life-Time-Inc` and `Life Time, Inc.` both become `lifetimeinc`) and compare.

- **Exactly one confident match** → use it, and mention which client you picked in your final
  report (so a wrong guess is easy to catch).
- **Zero matches, multiple matches, or not in a git repo at all** → do not guess. Use
  `AskUserQuestion` listing the client folder names found in step 2 and use the answer.

### 3. Resolve and validate an explicit path

*Explicit mode only — skip in inferred mode.*

Resolve the argument per **Resolving the path** above, then apply the **vault boundary** check. If
the resolved path is outside `~/Documents/Default/`, stop and ask the user; do not write.

Then check whether the file exists:

```bash
ls -l "$target"
```

- **Exists** → continue to step 4.
- **Does not exist** → do **not** create it silently. Show the user the fully resolved absolute
  path and use `AskUserQuestion` to confirm before creating the file and any missing parent
  directories. A mistyped directory or a forgotten `.md` lands here — that's the point. If the
  user declines, stop without writing anything.

### 4. Read the target file

`Read` the target file — the path computed in step 1 (inferred mode) or resolved in step 3
(explicit mode). If the directories or the file don't exist yet, treat it as empty — you'll create
it in step 7, not before.

### 5. Check for an existing "today" section

Look for the literal header `## {Month} {Day}, {Year}` (e.g. `## August 12, 2026`) in the content
just read.

- **Present** — this may be a second (or later) update in the same session. Do not re-summarize
  content already captured under it; only add material that isn't already there.
- **Absent** — this is the first update for today.

### 6. Synthesize the day's content from this conversation

Review the current conversation for substantive work: files changed, commands run, findings,
decisions, live-test results, commits made. Write it in the voice already used in this file's
entries:

- Factual, third-person-omitted ("Investigated X", "Found Y", "Fixed Z" — not "I did X").
- Concrete citations: exact file paths, exact error text, ticket/commit identifiers, in backticks.
- Links as `[text](url)`.
- Group related work into `### Topic` subsections when there are multiple distinct threads worth
  separating (see `August 10, 2026`/`August 12, 2026` in this vault for the pattern) — a single
  small item can just be a plain bullet under the date header instead, no subsection needed.
- When the new work resolves, contradicts, or otherwise relates to an open question/gap already
  logged earlier (in this file, or the previous week's file if relevant), say so explicitly — e.g.
  "Resolves the 8/10 open question directly...". Skim recent `##`/`###` headers for this before
  writing.
- Don't pad. A short session gets a short entry. Never fabricate detail that isn't grounded in the
  actual conversation.

### 7. Write the update

Splice the new content into the content read in step 4, in memory, then `Write` the whole file
back:

- **No existing today section** (new file, or today just isn't in it yet): append at the true end
  of the file:
  ```
  {existing content, if any}

  ## {Month} {Day}, {Year}

  {new content}
  ```
  Create the parent directories first if they don't exist (in explicit mode this was already
  confirmed in step 3).
- **Existing today section**: insert the new `### Topic` subsection(s) (or bullets) immediately
  before the *next* `## ` header that follows today's, or at the true end of the file if today's
  section is currently the last one. Everything before the insertion point — including anything the
  user wrote themselves — must come out byte-for-byte identical to what was read in step 4.

Never use `Edit` for this — the surrounding content is too variable to safely anchor a unique
`old_string`. Read the whole file, compute the new whole-file content in memory, `Write` it back.

### 8. Report

2–4 lines: which file was updated and the new subsection title(s)/bullet(s) added. Don't paste the
full appended text back if it's long — the user can open the file themselves.

- **Inferred mode** — also say which client was used and how it was determined (inferred or
  chosen), so a wrong guess is easy to catch.
- **Explicit mode** — say the path was supplied rather than inferred, and omit the client line
  entirely; there was no inference to double-check.

## Guardrails

- Append-only, always. Never edit, reorder, or remove anything already in the file — that includes
  content the user wrote themselves in a section this skill didn't create.
- Never fabricate work that didn't happen in this conversation.
- In inferred mode, if client inference is ambiguous or the current directory isn't recognizably
  tied to any client, ask — do not guess and silently write into the wrong client's journal.
- This skill only touches files under `~/Documents/Default/`. An explicit path argument may point
  anywhere inside that vault, but never outside it — a path that resolves outside stops and asks.
  It never touches git, commits, or pushes anything in the project repo being worked on.
- Never create a file at an explicitly supplied path without confirming first. Inferred mode may
  create its week file unprompted; explicit mode may not.
- This skill only targets *today*. If asked to log a different date, say this isn't supported yet
  and stop rather than silently writing under the wrong date. The path argument selects a *file*,
  not a *date* — pointed at last week's file, it still writes a section headed with today's date.
