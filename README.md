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

There is no Homebrew on Linux here — Ubuntu 24.04+ carries nearly every CLI
formula from the Brewfile in apt, so apt is the source of truth and
snap/upstream installers fill the few gaps.

```sh
git clone git@github.com:cebartling/dotfiles.git "$HOME/.dotfiles"
"$HOME/.dotfiles/scripts/Ubuntu/bootstrap.sh"
```

`scripts/Ubuntu/bootstrap.sh` is idempotent. It will:

1. `scripts/Ubuntu/install_tools.sh` — zsh, the two zsh plugins, starship
   and the CLI toolchain via apt; `vale`/`difftastic` via snap; `uv`,
   `watchexec` and `ast-grep` via their upstream installers. It also shims
   Debian's renamed `batcat`/`fdfind` back to `bat`/`fd` in `~/.local/bin`.
2. Install oh-my-zsh unattended (won't touch `~/.zshrc` or your login shell)
3. Install sdkman if missing
4. Install nvm into `$NVM_DIR` (no Homebrew formula to lean on)
5. `scripts/Ubuntu/install_fonts.sh` — JetBrainsMono Nerd Font, which
   `eza --icons` and the starship prompt both need
6. `scripts/Ubuntu/link.sh` — symlink `~/.zshrc` and
   `~/.config/starship.toml` (the cmux links are macOS-only and are skipped;
   ghostty is linked only if installed). Existing files are backed up to
   `<file>.backup.<timestamp>`.

Bootstrap deliberately does **not** change your login shell. Verify first,
then switch:

```sh
zsh -i -c exit          # should print nothing
time zsh -i -c exit     # ~150ms
chsh -s /usr/bin/zsh    # asks for your password; log out/in afterwards
```

Point the terminal at the Nerd Font (Ptyxis is the GNOME default on 24.04+):

```sh
gsettings set org.gnome.Ptyxis use-system-font false
gsettings set org.gnome.Ptyxis font-name 'JetBrainsMono Nerd Font 12'
```

Not available on Linux and intentionally skipped: `beads`/`bd`, `rtk`,
`mole`, `cliclick`, `whisperkit-cli`, and every `cask` / `vscode` entry in
the Brewfiles.

## Syncing an existing Mac

When `main` advances and you want to pull the changes onto another machine:

```sh
cd ~/.dotfiles
git pull --ff-only
~/.dotfiles/bootstrap.sh    # idempotent — only acts on what's missing
exec zsh                    # reload the shell
```

The bootstrap will pick up any newly added Brewfile entries and re-run
`link.zsh` (a no-op if everything is already linked correctly).

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
| [`ai-tools/claude-code/`](ai-tools/claude-code/README.md) | Claude Code config (CLAUDE.md, commands, hooks, skills) symlinked into `~/.claude` |

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
