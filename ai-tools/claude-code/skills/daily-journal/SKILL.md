---
name: daily-journal
description: Append a summary of the current conversation's work to the user's Obsidian daily work journal (Consulting/{Client}/Daily Journal/...), matching the file's existing dated-section conventions. Use when the user asks to "update my journal", "update the work summary in Obsidian", invokes /daily-journal, or wants today's work logged to their daily journal.
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
  separate built-in Obsidian daily-notes system and is not used by this skill.

## Workflow

### 1. Compute today's date and this week's file path

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

### 3. Read the week file

`Read` the file at the path computed in step 1. If the month directory or the week file doesn't
exist yet, treat it as empty — you'll create it in step 6, not before.

### 4. Check for an existing "today" section

Look for the literal header `## {Month} {Day}, {Year}` (e.g. `## August 12, 2026`) in the content
just read.

- **Present** — this may be a second (or later) update in the same session. Do not re-summarize
  content already captured under it; only add material that isn't already there.
- **Absent** — this is the first update for today.

### 5. Synthesize the day's content from this conversation

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

### 6. Write the update

Splice the new content into the content read in step 3, in memory, then `Write` the whole file
back:

- **No existing today section** (new file, or today just isn't in it yet): append at the true end
  of the file:
  ```
  {existing content, if any}

  ## {Month} {Day}, {Year}

  {new content}
  ```
  Create the year/month directories first if they don't exist.
- **Existing today section**: insert the new `### Topic` subsection(s) (or bullets) immediately
  before the *next* `## ` header that follows today's, or at the true end of the file if today's
  section is currently the last one. Everything before the insertion point — including anything the
  user wrote themselves — must come out byte-for-byte identical to what was read in step 3.

Never use `Edit` for this — the surrounding content is too variable to safely anchor a unique
`old_string`. Read the whole file, compute the new whole-file content in memory, `Write` it back.

### 7. Report

2–4 lines: which file was updated, which client was used (inferred or chosen, and how), and the
new subsection title(s)/bullet(s) added. Don't paste the full appended text back if it's long — the
user can open the file themselves.

## Guardrails

- Append-only, always. Never edit, reorder, or remove anything already in the file — that includes
  content the user wrote themselves in a section this skill didn't create.
- Never fabricate work that didn't happen in this conversation.
- If client inference is ambiguous or the current directory isn't recognizably tied to any client,
  ask — do not guess and silently write into the wrong client's journal.
- This skill only touches files under `~/Documents/Default/Consulting/`. It never touches git,
  commits, or pushes anything in the project repo being worked on.
- This skill only targets *today*. If asked to log a different date, say this isn't supported yet
  and stop rather than silently writing under the wrong date.
