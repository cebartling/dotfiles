# dotfiles

Christopher Bartling's macOS shell configuration: oh-my-zsh + starship,
lazy-loaded nvm/sdkman, syntax highlighting, autosuggestions, per-project
alias auto-loading, and a curated Brewfile.

Lives at `$HOME/.dotfiles` on each machine.

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
6. Symlink `~/.zshrc` → `$DOTFILES/zshrc` and
   `~/.config/starship.toml` → `$DOTFILES/configurations/starship.toml`
   (existing files are backed up to `<file>.backup.<timestamp>`)

After bootstrap completes, open a new terminal tab and run any of:

```sh
gh auth login
sdk version           # initializes sdkman on first call
nvm install --lts     # installs an LTS node on first call
~/.dotfiles/scripts/macOS/install_k8s_tools.zsh   # optional: k8s toolchain
```

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
| `bootstrap.sh` | One-shot installer for a fresh Mac |
| `Brewfile` | Canonical macOS package manifest (`brew bundle`) |
| `Brewfile.k8s` | Optional Kubernetes toolchain |
| [`PACKAGES.md`](PACKAGES.md) | Human-readable documentation of every tracked Brewfile package |
| `zshrc` | Tracked `~/.zshrc` (symlinked into place by `link.zsh`) |
| `oh-my-zsh/core.sh` | Theme + plugins config sourced before `oh-my-zsh.sh` |
| `aliases/core.sh` | Shared aliases (loaded on every shell) |
| `aliases/<project>.sh` | Per-project aliases auto-loaded by directory |
| `functions/core.sh` | Shared shell functions |
| `functions/project-aliases.sh` | `chpwd` hook that auto-sources project alias files |
| `paths/core.sh` | Extra `PATH` entries |
| `runtimes/*.sh` | Language runtime hooks (claude, sdkman, nvm — most lazy-loaded) |
| `configurations/starship.toml` | Starship prompt config (symlinked) |
| `scripts/macOS/link.zsh` | Idempotent symlink installer |
| `scripts/macOS/install_tools.zsh` | Thin wrapper around `brew bundle` |
| `scripts/macOS/install_k8s_tools.zsh` | Thin wrapper around `brew bundle --file=Brewfile.k8s` |
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
