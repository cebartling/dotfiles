---
name: daily-journal
description: Append a summary of the current conversation's work to the user's Obsidian daily work journal (Consulting/{Client}/Daily Journal/...), matching the file's existing dated-section conventions. Use when the user asks to "update my journal", "update the work summary in Obsidian", invokes /daily-journal, or wants today's work logged to their daily journal. Accepts an optional target-file path (e.g. `/daily-journal <path>`) that overrides the inferred client/period file.
tools: Bash, Read, Write, Glob, AskUserQuestion
---

# daily-journal

Log the current conversation's work into the user's Obsidian daily work journal, matching the
journal's existing conventions exactly, without disturbing anything already written there.

## Vault layout

Every journal lives under `~/Documents/Default/Consulting/{Client}/Daily Journal/{YYYY}/`, but
**the file-naming convention below that differs per client**. Three conventions exist today. Never
assume one — determine it from the client's own existing files (workflow step 2), and follow
whatever that client already does.

**The `Daily Journal` directory name is itself not uniform.** *Campfire Studio* spells it
`Daily journal`, lowercase `j`. Glob case-insensitively when locating a client's journal rather
than hardcoding the capitalization, and once found, put new files under the spelling that client
already uses.

### Convention A — weekly files in month directories (most clients)

```
Consulting/{Client}/Daily Journal/{YYYY}/{MM} - {Month}/{Month} {startDay}-{endDay}, {YYYY}.md
```

- Weeks are **Monday–Sunday**, clamped to the current calendar month — a week that would otherwise
  span two months gets truncated at the month boundary (e.g. `July 27-31, 2026.md` stops at
  month-end rather than continuing into August; the next week starts fresh, e.g.
  `August 3-9, 2026.md`).
- Month directory names are zero-padded with a single space around the dash: `08 - August`,
  `01 - January`. (One existing directory in this vault has a stray double space —
  `02 -  February` — that's a pre-existing typo; don't replicate it in anything you create.)
- Used by *Campfire Studio* and *Life Time, Inc* as of August 2026.

### Convention B — half-month files, sequentially numbered, flat in the year directory

```
Consulting/{Client}/Daily Journal/{YYYY}/{NN} - {Month} {startDay}-{endDay}, {YYYY}.md
```

- **No month subdirectory** — the files sit directly in `{YYYY}/`.
- Periods are **half-months**: day `1-15`, then day `16` through the month's last day (`16-31`,
  `16-30`, `16-28`). Not weeks, and never spanning a month boundary.
- `{NN}` is a zero-padded **sequential counter across the whole journal**, not derived from the
  date — it just increments as periods are added (`01 - February 15-28, 2026.md`,
  `02 - March 1-15, 2026.md`, … `13 - August 16-31, 2026.md`). The first file may cover a partial
  period, since it starts whenever the engagement did. To create a new file, take the highest
  existing `{NN}` and add one.
- Used by *Schoolhouse Educational Services* as of August 2026.

### Convention C — one file per day in month directories

```
Consulting/{Client}/Daily Journal/{YYYY}/{MM} - {Month}/{Month} {Day}, {YYYY}.md
```

- Month directories exactly as Convention A (`08 - August`, `09 - September`), but the file is a
  **single day**, not a range: `September 19, 2026.md`. The day is **not** zero-padded —
  `September 2, 2026.md`, not `September 02, 2026.md`, so a plain sort interleaves 1, 11, 12, 2.
- Because the filename carries the date, these are **single-day notes** in the sense step 5 means:
  there is no `## {Month} {Day}, {Year}` header inside. The body opens directly with a `## Topic`
  header, `###` beneath. Repeated updates the same day append further `## Topic` sections to the
  same file.
- **Frontmatter dates with `created:`, not `date:`** — see **Frontmatter** below.
- Used by *Replay Forensics Inc* as of September 2026.
- Legacy shape in the same journal: `2025/05 - May 2025.md` is a whole-month file sitting flat in
  the year directory, from before the per-day layout. Don't extend it and don't imitate it.

### Shared by all three conventions

- Files only exist when there's actual content — there is no empty placeholder for an idle period.
  Don't be surprised by gaps in the sequence.
- Files have **no title line** — after the frontmatter they start directly with the first header.
  Under A and B that is `## Month Day, Year`, and days are appended in chronological order down the
  file; under C the file *is* one day, so it is `## Topic` (see step 5).
- **Every file this skill creates gets YAML frontmatter** — see **Frontmatter** below. Most files
  already in the vault predate that rule and have none; they are left exactly as they are.
- **Do not confuse any of them with the vault's `Daily/` tree** — that's the separate built-in
  Obsidian daily-notes system, and inference never targets it. An explicit path argument may
  legitimately point there. Its notes live at
  `Daily/{YYYY}/{MM} - {Month}/{Month} {Day}, {Year}.md` — one file per day, so the date is the
  filename and the body opens directly with a `## Topic` header rather than a date header. Step 5
  detects this; step 7 writes accordingly. Note this is the same *filename* shape Convention C
  uses; the two differ by tree (`Daily/` vs `Consulting/`) and by frontmatter key.

## Frontmatter

**Every journal file this skill creates opens with YAML frontmatter.** The file shapes date
themselves differently, because one covers a range and the others cover a day — and the two
single-day cases do not agree on the key, so take it from the convention, not from the shape:

| Where | Key |
|---|---|
| Convention A / B (range filename) | `period: {start}/{end}` |
| Convention C (`Consulting/…`, per-day filename) | `created: {YYYY-MM-DD}` |
| `Daily/…` note | `date: {YYYY-MM-DD}` |

**Multi-day file** (Convention A or B) — the filename is a period, so the frontmatter carries that
period, not a single date:

```yaml
---
period: 2026-08-16/2026-08-31
tags:
  - journal
  - schoolhouse
  - pin-193
---
```

**Single-day note** — the filename is one date, so the date is exact. `Daily/…` notes use `date`:

```yaml
---
date: 2026-09-05
tags:
  - journal
  - storyboard-2026
  - tdd
---
```

Convention C files are the same shape but key it `created`, which is what that journal's recent
files actually carry:

```yaml
---
created: 2026-09-19
tags:
  - journal
  - replay-forensics
  - rp-454
  - bff
---
```

Older Convention C files are inconsistent — some have no frontmatter, one carries only `tags`, and
one uses `period` with a single date rather than a range. Don't propagate those; follow the table
above for anything new, and leave the existing ones alone.

Rules for all of them:

- `period` is `{startDate}/{endDate}`, both `YYYY-MM-DD`, matching the range in the filename.
  `created` and `date` are a single `YYYY-MM-DD`. Never more than one of the three.
- `tags` is a list, always led by `journal`. After that: the client or project slug (lowercase,
  hyphenated — `schoolhouse`, `life-time`, `storyboard-2026`), then a handful of topic tags drawn
  from the day's actual work (`mongodb`, `code-review`, `tdd`, a ticket id like `pin-193`).
  Lowercase and hyphenated throughout. Don't invent tags the entry doesn't support, and don't pad
  past roughly eight.
- **Never add frontmatter to a file that doesn't have it**, and never change `period`, `created` or
  `date` on a file that does — those describe what the file covers, which appending doesn't alter.
- **`tags` may be amended, but only when the user asks.** Appending a section is not itself a
  reason to touch the header: on a second update the tag list stays as written unless the user
  asks for a tag. When they do, add to the end of the list and change nothing else — never remove
  or reorder existing tags, even ones the new work doesn't support. The roughly-eight guidance
  above is for a list being written fresh; an amendment the user asked for isn't padding.

## Optional argument

The skill accepts a single optional argument — the path of the file to write:

- *(no argument)* — **inferred mode** (default). Derive the target file from today's date and the
  client, exactly as in workflow steps 1 and 2.
- *a file path* — **explicit mode**. Use that file as the target and **skip steps 1 and 2
  entirely** — no client inference, no convention detection, no period math.

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

### 1. Infer the client

*Skip this step entirely in explicit mode — the user named the file, so there is nothing to infer
and nothing to ask about.*

This comes first because the file-naming convention is **per client** (see **Vault layout**), so
the target path cannot be computed until the client is known.

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
Either signal alone is enough — the remote org and the sandbox directory often disagree (e.g.
`WICI-Apps` matches no client folder while its parent directory
`schoolhouse-educational-services` matches *Schoolhouse Educational Services* exactly).

- **Exactly one confident match** → use it, and mention which client you picked in your final
  report (so a wrong guess is easy to catch).
- **Zero matches, multiple matches, or not in a git repo at all** → do not guess. Use
  `AskUserQuestion` listing the client folder names found above and use the answer.

### 2. Determine the client's convention and compute the target path

*Skip the path computation in explicit mode — the target file is already known. You still need
today's date for the section header in step 5 and the time for the timestamp in step 7, so compute
`today` and `logged_at` regardless.*

```bash
today=$(date +%Y-%m-%d)
logged_at=$(date '+%-I:%M %p %Z')   # e.g. 2:32 PM CDT — see **Timestamp** under step 7
```

Look at what the client already has, newest last:

```bash
journal=$(find "$HOME/Documents/Default/Consulting/{Client}" -maxdepth 1 -iname 'daily journal' | head -1)
find "$journal" -name '*.md' | sort | tail -5
```

`-iname` because the directory's capitalization varies per client (see **Vault layout**).

Match the result against **Vault layout**. The month directory alone does not decide it — A and C
share it, and they differ on the *filename*:

- `.md` files directly in `{YYYY}/` with an `{NN} - ` prefix → **Convention B**.
- Inside a `{MM} - {Month}/` directory, filename is a date **range** (`September 14-20, 2026.md`) →
  **Convention A**.
- Inside a `{MM} - {Month}/` directory, filename is a **single** date (`September 19, 2026.md`) →
  **Convention C**.

An empty journal (a client with no files yet) defaults to Convention A. Ignore a lone whole-month
file like `2025/05 - May 2025.md` when classifying — it is a legacy shape, not a convention.

**Convention A — compute this week's Monday–Sunday window:**

```bash
dow=$(date +%u)   # 1=Mon .. 7=Sun
monday=$(date -j -v-$((dow-1))d -f "%Y-%m-%d" "$today" +%Y-%m-%d)
sunday=$(date -j -v+$((7-dow))d -f "%Y-%m-%d" "$today" +%Y-%m-%d)
```

Clamp `monday`/`sunday` to the current calendar month: if `monday`'s month differs from today's
month, replace it with the 1st of today's month; if `sunday`'s month differs from today's month,
replace it with the last day of today's month (`date -j -v1m -v+1d -v-1d ...` or equivalent).

Build the filename `{Month} {startDay}-{endDay}, {YYYY}.md` (month name spelled out once, e.g.
`August 10-16, 2026.md`) and the directory `{YYYY}/{MM} - {Month}/` (zero-padded month number).

**Convention B — compute this half-month period:**

- Today's day-of-month ≤ 15 → the period is `1-15`.
- Otherwise → the period is `16-{last day of this month}`
  (`date -j -v1d -v+1m -v-1d +%d`).

Then find the file for that period in `{YYYY}/`:

- **A file for this period already exists** → that's the target; keep its existing `{NN}` prefix.
- **It doesn't exist** → take the highest `{NN}` currently in `{YYYY}/`, add one, zero-pad to two
  digits, and build `{NN} - {Month} {startDay}-{endDay}, {YYYY}.md`. There is no month
  subdirectory — the file goes directly in `{YYYY}/`.

**Convention C — no period math at all:**

The file is today, so the path is `{YYYY}/{MM} - {Month}/{Month} {Day}, {YYYY}.md` with `{Day}` not
zero-padded (`September 2, 2026.md`). Nothing to clamp and no counter to increment.

Never create one convention's path for a client using another — that silently fragments the
journal into parallel layouts. The A/C confusion is the easy one to make, since both live in a
`{MM} - {Month}/` directory and only the filename differs.

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

`Read` the target file — the path computed in step 2 (inferred mode) or resolved in step 3
(explicit mode). If the directories or the file don't exist yet, treat it as empty — you'll create
it in step 7, not before.

### 5. Determine the file's shape, then check for existing content for today

Two file shapes exist in this vault, and they date their content differently:

- **Multi-day file** — one file holds many days, each introduced by a `## {Month} {Day}, {Year}`
  header, with `### Topic` subsections beneath. Convention A and B journals are this shape.
- **Single-day note** — the file *is* one day; the date lives in the **filename**, so there is no
  date *header* inside (it goes in the frontmatter instead, as `created` or `date` per the table
  under **Frontmatter**). Content opens with a `## Topic` header, `###` beneath. Both the
  `Daily/{YYYY}/{MM} - {Month}/{Month} {Day}, {Year}.md` notes **and Convention C Consulting
  journals** are this shape.

Decide the shape from the **filename** first, falling back to content:

1. Filename is a date *range* (`August 17-23, 2026.md`) → multi-day.
2. Filename is a single *date* (`August 17, 2026.md`) → single-day.
3. Neither → inspect the content just read: any `## {Month} {Day}, {Year}` header present →
   multi-day; otherwise single-day.

Inferred mode builds a range filename under Convention A and B, so it is multi-day there; under
Convention C it builds a single-date filename and is single-day. Either way the rule above already
gives the right answer from the filename the convention produced.

Then check whether today is already represented, which means different things per shape:

- **Multi-day** — look for the literal header `## {Month} {Day}, {Year}` (e.g. `## August 12,
  2026`) in the content just read. **Present** → this may be a second update in the same session.
  **Absent** → first update for today.
- **Single-day** — the whole file is today, so any existing content *is* today's. A non-empty file
  means a second (or later) update in the same session.

Either way, when today is already represented: do not re-summarize content already captured; only
add material that isn't already there.

### 6. Synthesize the day's content from this conversation

Review the current conversation for substantive work: files changed, commands run, findings,
decisions, live-test results, commits made. Write it in the voice already used in this file's
entries:

- Factual, third-person-omitted ("Investigated X", "Found Y", "Fixed Z" — not "I did X").
- Concrete citations: exact file paths, exact error text, ticket/commit identifiers, in backticks.
- Links as `[text](url)`.
- Group related work into topic sections when there are multiple distinct threads worth separating
  (see `August 10, 2026`/`August 12, 2026` in this vault for the pattern). In a multi-day file
  those are `### Topic` under the date header, and a single small item can just be a plain bullet
  under that header instead. In a single-day note they are `## Topic` at the top level, with `###`
  for subsections beneath.
- When the new work resolves, contradicts, or otherwise relates to an open question/gap already
  logged earlier (in this file, or the previous week's file if relevant), say so explicitly — e.g.
  "Resolves the 8/10 open question directly...". Skim recent `##`/`###` headers for this before
  writing.
- Don't pad. A short session gets a short entry. Never fabricate detail that isn't grounded in the
  actual conversation.

### 7. Write the update

Splice the new content into the content read in step 4, in memory, then `Write` the whole file
back. Follow the branch for the shape determined in step 5 — **never write a `## {Month} {Day},
{Year}` header into a single-day note**, where it would just duplicate the filename.

Create the parent directories first if they don't exist (in explicit mode this was already
confirmed in step 3).

**Timestamp.** Every update opens with an Obsidian `info` callout titled `Time tracking`
recording when it was logged, using `logged_at` from step 2:

```
> [!info] Time tracking
> Logged {h:MM} {AM|PM} {TZ}
```

It is one callout per *update*, not per topic: it sits directly above the new content, and several
topics added in one update share it. A second update the same day gets its own callout with the new
time, which is how same-day updates stay distinguishable. The callout stands on its own, never
inside a `##`/`###` header, so header text (and the Obsidian anchors built from it) stays clean.
Entries written before this rule have no timestamp, and older ones use a plain `*Logged …*` line;
leave them as they are.

**Multi-day file** (Convention A, Convention B):

- *Creating the file* — frontmatter (see **Frontmatter**), then today's section:
  ```
  ---
  period: {startDate}/{endDate}
  tags:
    - journal
    - {client-slug}
    - {topic}
  ---

  ## {Month} {Day}, {Year}

  > [!info] Time tracking
  > Logged {h:MM} {AM|PM} {TZ}

  {new content}
  ```
- *Existing file, today not in it yet* — append at the true end, adding **no** frontmatter even if
  the file has none:
  ```
  {existing content}

  ## {Month} {Day}, {Year}

  > [!info] Time tracking
  > Logged {h:MM} {AM|PM} {TZ}

  {new content}
  ```
- *Existing today section* — insert a `Time tracking` callout followed by the new
  `### Topic` subsection(s) (or bullets) immediately before the *next* `## ` header that follows
  today's, or at the true end of the file if today's section is currently the last one.

**Single-day note** (Convention C, `Daily/…`):

- *Creating the file* — frontmatter, then straight into the first topic. No date header: the
  filename already carries the date, and repeating it inside is duplication. The date key is
  `created` under Convention C and `date` under `Daily/…` — see the table under **Frontmatter**.
  ```
  ---
  date: {YYYY-MM-DD}
  tags:
    - journal
    - {project-slug}
    - {topic}
  ---

  > [!info] Time tracking
  > Logged {h:MM} {AM|PM} {TZ}

  ## {Topic}

  {new content}
  ```
- *Existing content* — append a `Time tracking` callout followed by the new `## Topic`
  section(s) at the true end of the file, leaving any existing frontmatter untouched and adding
  none if there is none.

In every branch, everything before the insertion point — including anything the user wrote
themselves, and any frontmatter already present — must come out byte-for-byte identical to what was
read in step 4. Writing an update never touches frontmatter; the only edit to an existing header is
a tag the user explicitly asked for, which is a request of its own and not part of this step.

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
  content the user wrote themselves in a section this skill didn't create, and the frontmatter
  already at the top of it.
- Never backfill frontmatter onto a file that has none — most of the vault predates the rule, and
  prepending to a file the skill didn't create is exactly the edit the line above forbids.
- The **one** permitted edit to existing frontmatter is adding a tag the user explicitly asked for.
  Add it to the end of the list; never remove or reorder what's there, and never touch `period`,
  `created` or `date`. Unprompted, frontmatter is still write-once-at-creation.
- Never fabricate work that didn't happen in this conversation.
- In inferred mode, if client inference is ambiguous or the current directory isn't recognizably
  tied to any client, ask — do not guess and silently write into the wrong client's journal.
- Never assume a naming convention. Read the client's existing files and follow them, even where
  that contradicts this document — the journal is the source of truth, and this document may
  simply be out of date. If a client's layout matches none of the three conventions, follow what's
  there and say so in the report rather than "correcting" it — Convention C was added to this
  document exactly that way, after *Replay Forensics Inc* turned out to match neither of the first
  two.
- This skill only touches files under `~/Documents/Default/`. An explicit path argument may point
  anywhere inside that vault, but never outside it — a path that resolves outside stops and asks.
  It never touches git, commits, or pushes anything in the project repo being worked on.
- Never create a file at an explicitly supplied path without confirming first. Inferred mode may
  create its period file unprompted; explicit mode may not.
- This skill only targets *today*. If asked to log a different date, say this isn't supported yet
  and stop rather than silently writing under the wrong date. The path argument selects a *file*,
  not a *date* — pointed at last week's file, it still writes a section headed with today's date.
