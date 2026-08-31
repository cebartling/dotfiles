# AI Agent Instructions

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

Uses **bd (beads)** for tracking. Run `bd prime` for full context.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- `bd` for ALL task tracking — NOT TodoWrite, TaskCreate, or markdown TODO lists
- `bd prime` for detailed commands + session close protocol
- `bd remember` for persistent knowledge — NOT MEMORY.md files

## Session Completion

Work NOT complete until `git push` succeeds.

**MANDATORY:**

1. File issues for remaining work
2. Run quality gates (tests, linters, builds) if code changed
3. Update issue status — close finished, update in-progress
4. **PUSH TO REMOTE:**
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. Clear stashes, prune remote branches
6. Verify all changes committed AND pushed
7. Hand off context for next session

**CRITICAL:**
- NOT complete until `git push` succeeds
- NEVER stop before pushing — leaves work stranded locally
- NEVER say "ready to push when you are" — YOU push
- Push fails → resolve and retry until succeeds
<!-- END BEADS INTEGRATION -->


## Build & Test

There is no build. "Tests" here means: does a shell still start cleanly, and do
the scripts still parse. Run these after touching `zshrc`, `aliases/`,
`functions/`, or anything under `scripts/`.

```bash
# Parse checks — never commit a script that does not parse
bash -n scripts/Ubuntu/*.sh bootstrap.sh ai-tools/claude-code/install.sh
zsh  -n zshrc aliases/core.sh functions/*.sh oh-my-zsh/core.sh

# A login shell must start SILENTLY. Any stderr is a bug.
env -u CLAUDECODE zsh -i -c exit

# Startup budget is ~150ms. Measure with hyperfine, not `time` — and unset
# CLAUDECODE, or zshrc takes its eager-nvm branch and you will measure ~350ms
# and "fix" a problem that does not exist.
hyperfine --warmup 3 'env -u CLAUDECODE zsh -i -c exit'

# Linkers are idempotent: a second run prints `ok` for every entry, never
# `backup`. A `backup` line on a re-run means something diverged.
scripts/Ubuntu/link.sh          # or scripts/macOS/link.zsh
bash ai-tools/claude-code/install.sh

# Relative links in the docs must resolve
grep -roE '\]\([^)h][^)]*\)' README.md PACKAGES.md ai-tools/claude-code/README.md
```

## Architecture Overview

One repo, two platforms, three moving parts:

- **`zshrc` is a single file shared by macOS and Linux.** There is no per-OS
  copy. Every platform-specific branch is guarded by `$OSTYPE` or an existence
  test, so pulling on the other machine is a behavioural no-op.
- **Per-OS installers.** `scripts/macOS/*` drives Homebrew and the `Brewfile*`
  manifests. `scripts/Ubuntu/*` drives apt, with snap and upstream release
  binaries for the gaps — there is no Homebrew on Linux here.
- **Everything reaches `$HOME` by symlink**, never by copy, so edits in either
  tree show up in both and `git status` is a faithful diff. The linkers back up
  any pre-existing real file to `<path>.backup.<timestamp>`.

`bootstrap.sh` is macOS and redirects to `scripts/Ubuntu/bootstrap.sh` on Linux.
The Claude Code config under `ai-tools/claude-code/` is a separate, manual
`install.sh` — bootstrap does not run it.

## Conventions & Patterns

**Guard, do not fork.** When something differs per platform, branch inside the
shared file behind `$OSTYPE` or a `command -v` / `-d` test. Never create a
parallel copy of a tracked config.

**Beware installers that write to shell profiles.** `~/.zshrc` is a symlink to
`$DOTFILES/zshrc`, so an installer appending to it is editing this repo. Known
offenders and their opt-outs: nvm (`PROFILE=/dev/null`), uv
(`INSTALLER_NO_MODIFY_PATH=1`), rustup (`--no-modify-path`), bun and pnpm (use
the release archive, not the curl installer), oh-my-zsh and sdkman (they write
one anyway — `scripts/Ubuntu/bootstrap.sh` snapshots and discards it).
**Check for this on every new tool.**

**Single binaries go to `~/.local/bin`, not `/usr/bin`.** It is already on
`$path`, and `dpkg-deb -x` + `install -m 0755` needs no root. Assume sudo is
password-prompted and unavailable to an agent.

**Prefer lazy loading in `zshrc`.** nvm, sdkman and pyenv all load on first use.
An eager `eval "$(tool init -)"` is a subprocess on every single shell.

**Verify against the machine, not from memory.** Package names and binary names
drift (Debian ships `bat` as `batcat`, `fd` as `fdfind`). To find whether a
Homebrew formula has a Linux build, query the formula API —
`https://formulae.brew.sh/api/formula/<name>.json` gives the real homepage,
source URL and bottle platforms. Guessing at GitHub orgs has produced wrong
"it does not exist on Linux" conclusions more than once.

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer)

## Golden Rule

**Always prefix with `rtk`**. Dedicated filter → uses it. No filter → passes through unchanged. Always safe.

**In `&&` chains too:**
```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## Commands by Workflow

### Build & Compile (80-90% savings)
```bash
rtk cargo build         # Cargo build output
rtk cargo check         # Cargo check output
rtk cargo clippy        # Clippy warnings grouped by file (80%)
rtk tsc                 # TypeScript errors grouped by file/code (83%)
rtk lint                # ESLint/Biome violations grouped (84%)
rtk prettier --check    # Files needing format only (70%)
rtk next build          # Next.js build with route metrics (87%)
```

### Test (60-99% savings)
```bash
rtk cargo test          # Cargo test failures only (90%)
rtk go test             # Go test failures only (90%)
rtk jest                # Jest failures only (99.5%)
rtk vitest              # Vitest failures only (99.5%)
rtk playwright test     # Playwright failures only (94%)
rtk pytest              # Python test failures only (90%)
rtk rake test           # Ruby test failures only (90%)
rtk rspec               # RSpec test failures only (60%)
rtk test <cmd>          # Generic test wrapper - failures only
```

### Git (59-80% savings)
```bash
rtk git status          # Compact status
rtk git log             # Compact log (works with all git flags)
rtk git diff            # Compact diff (80%)
rtk git show            # Compact show (80%)
rtk git add             # Ultra-compact confirmations (59%)
rtk git commit          # Ultra-compact confirmations (59%)
rtk git push            # Ultra-compact confirmations
rtk git pull            # Ultra-compact confirmations
rtk git branch          # Compact branch list
rtk git fetch           # Compact fetch
rtk git stash           # Compact stash
rtk git worktree        # Compact worktree
```

Passthrough works for ALL git subcommands, even unlisted.

### GitHub (26-87% savings)
```bash
rtk gh pr view <num>    # Compact PR view (87%)
rtk gh pr checks        # Compact PR checks (79%)
rtk gh run list         # Compact workflow runs (82%)
rtk gh issue list       # Compact issue list (80%)
rtk gh api              # Compact API responses (26%)
```

### JavaScript/TypeScript (70-90% savings)
```bash
rtk pnpm list           # Compact dependency tree (70%)
rtk pnpm outdated       # Compact outdated packages (80%)
rtk pnpm install        # Compact install output (90%)
rtk npm run <script>    # Compact npm script output
rtk npx <cmd>           # Compact npx command output
rtk prisma              # Prisma without ASCII art (88%)
```

### Files & Search (60-75% savings)
```bash
rtk ls <path>           # Tree format, compact (65%)
rtk read <file>         # Code reading with filtering (60%)
rtk grep <pattern>      # Search grouped by file (75%). Format flags (-c, -l, -L, -o, -Z) run raw.
rtk find <pattern>      # Find grouped by directory (70%)
```

### Analysis & Debug (70-90% savings)
```bash
rtk err <cmd>           # Filter errors only from any command
rtk log <file>          # Deduplicated logs with counts
rtk json <file>         # JSON structure without values
rtk deps                # Dependency overview
rtk env                 # Environment variables compact
rtk summary <cmd>       # Smart summary of command output
rtk diff                # Ultra-compact diffs
```

### Infrastructure (85% savings)
```bash
rtk docker ps           # Compact container list
rtk docker images       # Compact image list
rtk docker logs <c>     # Deduplicated logs
rtk kubectl get         # Compact resource list
rtk kubectl logs        # Deduplicated pod logs
```

### Network (65-70% savings)
```bash
rtk curl <url>          # Compact HTTP responses (70%)
rtk wget <url>          # Compact download output (65%)
```

### Meta
```bash
rtk gain                # View token savings statistics
rtk gain --history      # View command history with savings
rtk discover            # Analyze Claude Code sessions for missed RTK usage
rtk proxy <cmd>         # Run command without filtering (for debugging)
rtk init                # Add RTK instructions to CLAUDE.md
rtk init --global       # Add RTK to ~/.claude/CLAUDE.md
```

## Token Savings

| Category | Commands | Typical Savings |
|----------|----------|-----------------|
| Tests | vitest, playwright, cargo test | 90-99% |
| Build | next, tsc, lint, prettier | 70-87% |
| Git | status, log, diff, add, commit | 59-80% |
| GitHub | gh pr, gh run, gh issue | 26-87% |
| Package Managers | pnpm, npm, npx | 70-90% |
| Files | ls, read, grep, find | 60-75% |
| Infrastructure | docker, kubectl | 85% |
| Network | curl, wget | 65-70% |

Overall: **60-90% token reduction** on common dev ops.
<!-- /rtk-instructions -->
