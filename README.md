# dotfiles

Christopher Bartling's shell configuration for macOS and Ubuntu:
oh-my-zsh + starship, lazy-loaded nvm/sdkman, syntax highlighting,
autosuggestions, per-project alias auto-loading, and a curated Brewfile.

Lives at `$HOME/.dotfiles` on each machine. The tracked
[`zshrc`](zshrc) is shared by both platforms — every OS-specific branch in
it is guarded, so pulling on the other machine is a behavioural no-op.

## Setting up a new Mac

One-time bootstrap on a brand-new macOS install:

```sh
git clone git@github.com:cebartling/dotfiles.git "$HOME/.dotfiles"
"$HOME/.dotfiles/bootstrap.sh"
```

`bootstrap.sh` is idempotent. It will:

1. Ensure Xcode Command Line Tools
2. Install Homebrew if missing
3. `brew bundle` everything in [`Brewfile`](Brewfile)
4. Install oh-my-zsh unattended (won't touch `~/.zshrc` or your login shell)
5. Install sdkman if missing
6. Symlink tracked config into place: `~/.zshrc`, starship, ghostty,
   and cmux (both `~/.config/cmux/` and the embedded-Ghostty config under
   `~/Library/Application Support/com.cmuxterm.app/`). Existing files are
   backed up to `<file>.backup.<timestamp>`.

After bootstrap completes, open a new terminal tab and run any of:

```sh
gh auth login
sdk version           # initializes sdkman on first call
nvm install --lts     # installs an LTS node on first call
~/.dotfiles/scripts/macOS/install_k8s_tools.zsh   # optional: k8s toolchain
```

## Setting up a new Ubuntu box

There is no Homebrew here. Ubuntu 24.04+ carries nearly every CLI formula from
the Brewfile in apt, so **apt is the source of truth on Linux**, with snap and
upstream release binaries filling the gaps.

```sh
git clone git@github.com:cebartling/dotfiles.git "$HOME/.dotfiles"
"$HOME/.dotfiles/scripts/Ubuntu/bootstrap.sh"
```

`scripts/Ubuntu/bootstrap.sh` is idempotent. It will:

1. [`install_tools.sh`](scripts/Ubuntu/install_tools.sh) — the CLI toolchain
   (see [Where Linux packages come from](#where-linux-packages-come-from))
2. Install oh-my-zsh unattended (won't touch `~/.zshrc` or your login shell)
3. Install sdkman if missing
4. Install nvm into `$NVM_DIR` — there is no Homebrew nvm formula to lean on,
   so nvm proper is installed with `PROFILE=/dev/null` to keep its installer
   out of `~/.zshrc`
5. [`install_fonts.sh`](scripts/Ubuntu/install_fonts.sh) — JetBrainsMono Nerd
   Font, which `eza --icons` and the starship prompt both need
6. [`link.sh`](scripts/Ubuntu/link.sh) — symlink `~/.zshrc` and
   `~/.config/starship.toml`. The cmux links are macOS-only and skipped;
   ghostty is linked only if installed. Existing files are backed up to
   `<file>.backup.<timestamp>`.

Then install the Claude Code config, which bootstrap deliberately does not
touch (see [ai-tools/claude-code/](ai-tools/claude-code/README.md)):

```sh
bash ~/.dotfiles/ai-tools/claude-code/install.sh
```

### Switching to zsh

Bootstrap does **not** run `chsh` — verify the config works before committing
your login shell to it:

```sh
zsh -i -c exit          # should print nothing at all
time zsh -i -c exit     # ~150ms
chsh -s /usr/bin/zsh    # asks for your password; log out/in afterwards
```

Point the terminal at the Nerd Font (Ptyxis is the GNOME default on 24.04+):

```sh
gsettings set org.gnome.Ptyxis use-system-font false
gsettings set org.gnome.Ptyxis font-name 'JetBrainsMono Nerd Font 12'
```

### Where Linux packages come from

| Source | Packages |
|---|---|
| **apt** | zsh, zsh-autosuggestions, zsh-syntax-highlighting, starship, eza, bat, fd-find, ripgrep, fzf, zoxide, git-delta, du-dust, procs, tree, tmux, jq, yq, direnv, atuin, lazygit, glow, hyperfine, just, tokei, pre-commit, gitleaks, httpie, xh, gh, pipx, python3-poetry |
| **snap** | vale, difftastic |
| **upstream release** | uv, watchexec, ast-grep, [bd (beads)](https://github.com/steveyegge/beads), [rtk](https://github.com/rtk-ai/rtk), [bun](https://github.com/oven-sh/bun) |

Anything installed from an upstream release lands in `~/.local/bin`, which the
tracked `zshrc` already puts on `$path` — no sudo for single binaries.

**Renamed binaries.** Debian ships `bat` as `batcat` and `fd-find` as `fdfind`
to avoid file clashes. `install_tools.sh` shims both back to their upstream
names in `~/.local/bin`, so `aliases/core.sh` needs no Linux special-casing.
`git-delta` correctly installs `/usr/bin/delta` and needs no shim.

**Two traps worth remembering:**

- The npm package named `rtk` is [cliffano/rtk](https://github.com/cliffano/rtk),
  an unrelated changelog tool. The Rust Token Killer is `rtk-ai/rtk`. When
  hunting for a Linux build of a Brewfile formula, the Homebrew core API
  (`formulae.brew.sh/api/formula/<name>.json`) gives you the real homepage and
  source URL — far more reliable than guessing at GitHub orgs.
- `ast-grep` also ships an `sg` alias, which collides with the setgid binary
  from the `login` package on some systems. `install_tools.sh` only takes `sg`
  if nothing else owns the name.

Not available on Linux and intentionally skipped: `mole`, `cliclick`,
`whisperkit-cli`, and every `cask` / `vscode` entry in the Brewfiles. The
optional k8s and cloud toolchains have no Linux installer yet.

### How the shared zshrc stays cross-platform

`zshrc` is one file used by both platforms. Every OS-specific branch is guarded
so a `git pull` on the other machine is a behavioural no-op:

| Concern | How it is guarded |
|---|---|
| `$EDITOR` | first of `code`/`cursor`/`zed`/`nvim`/`vim`/`nano` that is installed |
| `PNPM_HOME` | `$OSTYPE` — `~/Library/pnpm` on macOS, XDG path elsewhere |
| zsh plugins | first hit across `$HOMEBREW_PREFIX/share`, `/usr/share`, `/usr/local/share` |
| nvm | resolves `$HOMEBREW_PREFIX/opt/nvm` then `$NVM_DIR`; **defines no wrappers at all if neither exists** |
| oh-my-zsh | guarded, with an actionable message instead of a hard error |
| libpq | only prepended where the directory exists |

That nvm guard fixes a real bug: the `nvm`/`node`/`npm`/`npx` wrappers used to
be defined unconditionally, so on any machine without the Homebrew nvm formula
the first `node` call would `unset -f` itself, fail to source a missing
`nvm.sh`, then recurse into a command that was no longer there.

## Syncing an existing machine

When `main` advances and you want to pull the changes onto another machine:

```sh
cd ~/.dotfiles
git pull --ff-only
~/.dotfiles/bootstrap.sh                     # macOS
~/.dotfiles/scripts/Ubuntu/bootstrap.sh      # Linux
exec zsh                                     # reload the shell
```

The bootstrap will pick up any newly added packages and re-run the linker
(a no-op if everything is already linked correctly). Re-run
`ai-tools/claude-code/install.sh` too if the Claude Code config changed.

To verify the sync worked:

```sh
readlink ~/.zshrc                       # → ~/.dotfiles/zshrc
readlink ~/.config/starship.toml        # → ~/.dotfiles/configurations/starship.toml
which starship eza bat fzf
time zsh -i -c exit                     # ~150ms
```

## Per-machine overrides

`~/.dotfiles/zshrc` is shared across every Mac. For things that should
only run on one machine (work proxies, employer git identity, host-specific
PATH entries, secrets), drop them in `~/.zshrc.local`. The tracked `zshrc`
sources it at the very end if present, so anything you put there overrides
the defaults. `~/.zshrc.local` is gitignored.

```sh
cp ~/.dotfiles/.zshrc.local.example ~/.zshrc.local
$EDITOR ~/.zshrc.local
```

## Updating the package manifest

When you install a new tool you want on every Mac:

```sh
brew install <thing>
$EDITOR ~/.dotfiles/Brewfile           # add the entry, group it sensibly
brew bundle check --file=~/.dotfiles/Brewfile     # confirm clean
git add Brewfile && git commit && git push
```

To see drift between this Mac and the canonical Brewfile:

```sh
brew bundle check --file=~/.dotfiles/Brewfile --verbose
```

## Layout

| Path | Purpose |
|---|---|
| `bootstrap.sh` | One-shot installer for a fresh Mac (redirects to `scripts/Ubuntu/bootstrap.sh` on Linux) |
| `Brewfile` | Canonical macOS package manifest (`brew bundle`) |
| `Brewfile.k8s` | Optional Kubernetes toolchain |
| `Brewfile.cloud` | Optional cloud management tooling (provider CLIs + Hashicorp IaC) |
| [`PACKAGES.md`](PACKAGES.md) | Human-readable documentation of every tracked Brewfile package |
| `zshrc` | Tracked `~/.zshrc`, shared by macOS and Linux (symlinked into place by `link.zsh` / `link.sh`) |
| `oh-my-zsh/core.sh` | Theme + plugins config sourced before `oh-my-zsh.sh` |
| `aliases/core.sh` | Shared aliases (loaded on every shell) |
| `aliases/<project>.sh` | Per-project aliases auto-loaded by directory |
| `functions/core.sh` | Shared shell functions |
| `functions/project-aliases.sh` | `chpwd` hook that auto-sources project alias files |
| `paths/core.sh` | Extra `PATH` entries |
| `runtimes/*.sh` | Language runtime hooks (claude, sdkman, nvm — most lazy-loaded) |
| `configurations/starship.toml` | Starship prompt config (symlinked) |
| `configurations/ghostty/config` | Standalone Ghostty.app config (symlinked into `~/.config/ghostty/`) |
| [`configurations/cmux/`](configurations/cmux/README.md) | cmux app + embedded-Ghostty config (symlinked into `~/.config/cmux/` and `~/Library/Application Support/com.cmuxterm.app/`) |
| `scripts/macOS/link.zsh` | Idempotent symlink installer |
| `scripts/macOS/install_tools.zsh` | Thin wrapper around `brew bundle` |
| `scripts/macOS/install_k8s_tools.zsh` | Thin wrapper around `brew bundle --file=Brewfile.k8s` |
| `scripts/macOS/install_cloud_tools.zsh` | Thin wrapper around `brew bundle --file=Brewfile.cloud` |
| `scripts/Ubuntu/bootstrap.sh` | One-shot installer for a fresh Ubuntu box |
| `scripts/Ubuntu/install_tools.sh` | CLI toolchain via apt/snap/upstream installers |
| `scripts/Ubuntu/install_fonts.sh` | JetBrainsMono Nerd Font into `~/.local/share/fonts` |
| `scripts/Ubuntu/link.sh` | Idempotent symlink installer (Linux targets) |
| [`ai-tools/claude-code/`](ai-tools/claude-code/README.md) | Claude Code config (CLAUDE.md, RTK.md, settings.json, commands, hooks, skills) symlinked into `~/.claude` |

## Per-project aliases

Per-project alias files live in `aliases/<project>.sh` and are sourced
automatically the first time you `cd` into a registered directory (or
any subdirectory). The wiring lives in `functions/project-aliases.sh`,
which installs a `chpwd` hook driven by the `PROJECT_ALIAS_MAP`
associative array.

This replaces an older pattern where you'd run a `<project>-aliases`
command by hand to load them. Those loader commands no longer exist —
just `cd` into the project root and the aliases appear. To force-load
without changing directory:

```sh
source "$DOTFILES/aliases/<project>.sh"
```

By convention each project alias file defines a `<project>-help`
function that prints the available aliases (e.g. `lifetime-help`).

To register a new project, add an entry to `PROJECT_ALIAS_MAP` in
`functions/project-aliases.sh` mapping the directory prefix to the
alias filename:

```sh
typeset -gA PROJECT_ALIAS_MAP=(
  ...
  [$HOME/github-sandbox/my-new-project]=my-new-project.sh
)
```

Then create `aliases/my-new-project.sh`. Entries whose directory does
not exist are silently skipped, so stale projects can stay in the map
without causing errors.

## License

MIT — see [LICENSE](LICENSE).
