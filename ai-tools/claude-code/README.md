# Claude Code config

User-scoped Claude Code config — `CLAUDE.md`, custom slash commands,
hooks, and authored skills — tracked in this dotfiles repo and
symlinked into `~/.claude` by [`install.sh`](install.sh).

## Install / sync

```sh
bash ~/.dotfiles/ai-tools/claude-code/install.sh
```

Idempotent. Safe to run any time. Pre-existing real files at the
destination are backed up to `<path>.backup.<timestamp>` before being
replaced with a symlink — nothing is overwritten in place.

This step is **not** wired into `bootstrap.sh`. Run it explicitly on
each machine after cloning the dotfiles repo.

## What gets linked

| Source (in repo) | Destination |
|---|---|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `commands/<name>.md` | `~/.claude/commands/<name>.md` |
| `hooks/<name>.yaml` | `~/.claude/hooks/<name>.yaml` |
| `skills/<name>/` | `~/.claude/skills/<name>/` |

Each entry under `skills/` is symlinked as a whole subdirectory, so
multi-file skills (e.g. `SKILL.md` plus supporting files) work without
needing per-file links.

## Editing

Both ends of every symlink are the same file. Edit either location:

- `~/.dotfiles/ai-tools/claude-code/skills/self-review/SKILL.md`
- `~/.claude/skills/self-review/SKILL.md`

…and `git status` in the dotfiles repo will pick up the change. No
re-install step needed after editing.

## Adding a new skill

```sh
mkdir ~/.dotfiles/ai-tools/claude-code/skills/my-skill
$EDITOR ~/.dotfiles/ai-tools/claude-code/skills/my-skill/SKILL.md
bash ~/.dotfiles/ai-tools/claude-code/install.sh
```

The skill is now available as `/my-skill` in any Claude Code session.

Adding a new command or hook follows the same pattern — drop the file
under `commands/` or `hooks/` and re-run `install.sh`.

## Coexistence with plugin-managed skills

`~/.claude/skills/` may contain symlinks installed by Claude Code
plugins (e.g. `find-skills`, `make-interfaces-feel-better` →
`~/.agents/skills/...`). `install.sh` only touches entries that exist
under this repo's `skills/` directory, so plugin-managed entries are
left alone.

If a plugin and this repo ever provide a skill with the same name,
the one this repo provides wins (the symlink is overwritten, with the
prior link backed up alongside).

## Verifying the sync

```sh
ls -la ~/.claude/skills/
# Each authored skill should be a symlink into ~/.dotfiles/ai-tools/claude-code/skills/

readlink ~/.claude/CLAUDE.md
# → /Users/<you>/.dotfiles/ai-tools/claude-code/CLAUDE.md
```

A second run of `install.sh` should print `ok` for every entry. Any
`backup` line on a re-run is a signal that something diverged — check
the `.backup.<timestamp>` file and reconcile.

## Cleaning up old backups

After verifying the sync took, the `.backup.*` files left behind by
the first symlink pass are safe to delete:

```sh
ls ~/.claude/*.backup.* ~/.claude/**/*.backup.* 2>/dev/null
# Eyeball, then:
rm ~/.claude/CLAUDE.md.backup.*
```

## Layout decisions

- **Symlinks, not copies.** Edits in either tree show up in both
  immediately and `git status` is a faithful diff. Copy-based sync
  silently drifts.
- **Per-skill symlinks, not a single `~/.claude/skills` symlink.**
  Plugin-managed skill entries (`find-skills`, etc.) need to coexist
  in that directory; symlinking the whole dir to dotfiles would
  conflate plugin sync with dotfiles sync.
- **Plugin-compatible layout.** Each skill is `<name>/SKILL.md` —
  identical to the layout Claude Code plugins use. If these skills
  ever graduate to a personal plugin, only a manifest needs to be
  added; no files move.
