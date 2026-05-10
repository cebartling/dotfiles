# cmux configuration

[cmux](https://cmux.com/) is installed via the root [`Brewfile`](../../Brewfile)
(`cask "manaflow-ai/cmux/cmux"`). This directory tracks every cmux config
file that lives in a writable location on the user's machine, symlinked into
place by [`scripts/macOS/link.zsh`](../../scripts/macOS/link.zsh).

## What this manages

| Repo file | Runtime path |
| --- | --- |
| [`cmux.json`](cmux.json) | `~/.config/cmux/cmux.json` |
| [`settings.json`](settings.json) | `~/.config/cmux/settings.json` |
| [`config.ghostty`](config.ghostty) | `~/Library/Application Support/com.cmuxterm.app/config.ghostty` |

`link.zsh` backs up any existing real file to `<file>.backup.<timestamp>`
before replacing it with a symlink, so re-running on a machine that already
has hand-edited cmux config is safe.

## Why three files

### `cmux.json` and `settings.json`

cmux ships with two sibling JSONC files in `~/.config/cmux/`:

- `cmux.json` — `$schema` points at `cmux.schema.json`.
- `settings.json` — `$schema` points at `cmux-settings.schema.json`.

The file header comment cmux generates says `~/.config/cmux/settings.json`
takes precedence over the Application Support fallback, but it does not
clarify the relationship between `cmux.json` and `settings.json`. To stay
defensive against cmux changing which filename wins in a future release,
both are tracked. Keep them in sync when adding real customizations.

Format: **JSONC** — JSON with comments and trailing commas.

### `config.ghostty`

cmux embeds [Ghostty](https://ghostty.org/) as its terminal. The cmux app
reads its embedded-terminal config from:

```
~/Library/Application Support/com.cmuxterm.app/config.ghostty
```

This is **distinct** from the standalone Ghostty.app config managed at
[`../ghostty/config`](../ghostty/config) (which targets `~/.config/ghostty/config`).
Editing one does **not** affect the other — keep them in sync manually if
you want the same terminal feel in both apps.

Format: **plain Ghostty config syntax** (`key = value`, `#` comments). See
[Ghostty config docs](https://ghostty.org/docs/config) for the full reference.

> **Caveat:** the `config.ghostty` path under `Application Support/com.cmuxterm.app/`
> is **not documented** at https://cmux.com/docs/configuration as of this
> writing — it was discovered empirically. The published docs only list
> `~/.config/ghostty/config` and `~/Library/Application Support/com.mitchellh.ghostty/config`
> for cmux's terminal config. If a future cmux release starts honoring those
> paths instead, this file may stop being load-bearing — verify with
> `readlink` and a config edit before assuming changes still take effect.

## Editing

Edit files **in this repo**. The symlinks make the runtime paths follow
along, and changes take effect on the next cmux launch.

Do **not** edit the runtime paths directly — they are symlinks back here,
so edits there will modify the tracked files in this repo with no commit
trail.

## Project-scoped overrides

cmux supports a per-project override file at `<project>/.cmux/cmux.json`
(JSONC). Per the [cmux docs](https://cmux.com/docs/configuration) it can
override **actions**, **commands**, and **UI action wiring**, but it
**cannot** override global app preferences — those always come from
`~/.config/cmux/`.

Minimal example committed inside a project repo:

```jsonc
// <project>/.cmux/cmux.json
{
  "$schema": "https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json",
  "schemaVersion": 1,
  "commands": {
    // project-specific actions / commands here
  }
}
```

No template is shipped from this repo — projects opt in ad hoc.

## Initial setup / re-link

`bootstrap.sh` runs `link.zsh` automatically. To force a re-link without a
full bootstrap:

```sh
zsh ~/.dotfiles/scripts/macOS/link.zsh
```

Idempotent: lines whose symlink already points at the right source print
`ok` and do nothing.

## Resetting to cmux defaults

To regenerate a clean template for any of the three files:

1. Quit cmux.
2. Delete or rename the file in this repo.
3. Re-run `link.zsh` (the runtime symlink will now be dangling, which is fine).
4. Launch cmux — it will recreate the JSON template, or recreate
   `Application Support/com.cmuxterm.app/config.ghostty` with its defaults.
5. Optionally copy the regenerated content back into this repo and commit.

## Upstream references

- cmux: https://cmux.com/
- cmux configuration docs: https://cmux.com/docs/configuration
- Ghostty configuration docs: https://ghostty.org/docs/config
