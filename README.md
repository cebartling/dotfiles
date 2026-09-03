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
| **apt** | zsh, zsh-autosuggestions, zsh-syntax-highlighting, starship, eza, bat, fd-find, ripgrep, fzf, zoxide, git-delta, du-dust, procs, tree, tmux, jq, yq, direnv, atuin, lazygit, glow, hyperfine, just, tokei, pre-commit, gitleaks, httpie, xh, gh, pipx, python3-poetry, weston, wayland-utils |
| **snap** | vale, difftastic |
| **apt (`pkgs.tailscale.com`)** | tailscale — opt-in, the only third-party apt source here (see below) |
| **upstream release** | [uv](https://astral.sh/uv), watchexec, ast-grep, [bd (beads)](https://github.com/steveyegge/beads), [rtk](https://github.com/rtk-ai/rtk), [bun](https://github.com/oven-sh/bun), [pnpm](https://github.com/pnpm/pnpm), [rustup](https://rustup.rs), [pyenv](https://github.com/pyenv/pyenv) |

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

### Headless Wayland (`wlheadless-run`)

The Wayland stand-in for `xvfb` / `xvfb-run`. There is no single drop-in, because
the job splits in two: the display is a headless compositor (`weston --backend=headless`),
and the `xvfb-run` half is **not packaged by anyone** — Wayland has no `-displayfd`,
so something has to poll for the compositor's socket in `$XDG_RUNTIME_DIR`.

[`scripts/Ubuntu/wlheadless-run`](scripts/Ubuntu/wlheadless-run) is that half. It is
the one tracked executable in this repo meant to land on `$PATH`; `link.sh` symlinks
it into `~/.local/bin`.

```sh
wlheadless-run -- wayland-info              # the `xvfb-run xdpyinfo` equivalent
wlheadless-run --size 1280x720 -- my-test
```

Each run gets a private socket, so concurrent invocations do not collide — the
behaviour `xvfb-run` puts behind `-a`, here unconditional. Exit codes propagate,
including `128+signum` when the wrapper itself is interrupted (130 on `SIGINT`,
143 on `SIGTERM`), so an interrupted run is never mistaken for a pass.
The compositor runs with `--renderer=pixman` (no GPU), `--no-config` (a stray
`~/.config/weston.ini` cannot change behaviour) and `--idle-time=0` (no blanking
mid-run).

> **This does not replace `xvfb`.** An X11-only program under Wayland needs this
> compositor *plus* nested Xwayland — more moving parts than just running Xvfb,
> which is still in apt and still correct there. Use `wlheadless-run` for
> Wayland-native clients. For browser tests you likely need neither: Chrome and
> Firefox have real headless modes.

`cage`, `sway`, `labwc` and `mutter --headless` are all in apt too and would each
work; `weston` is installed here because the headless backend is a first-class
feature of the reference compositor rather than an env-var side door.

### Kubernetes (opt-in)

```sh
~/.dotfiles/scripts/Ubuntu/install_k8s_tools.sh
```

Not wired into bootstrap, mirroring `scripts/macOS/install_k8s_tools.zsh`.
Ubuntu packages none of this, and every vendor's install doc wants a
third-party apt repository — `pkgs.k8s.io`, `baltocdn`, and so on. **None of
that is necessary.** Each CLI is a static Go binary published upstream, so they
go into `~/.local/bin` with no root and no extra apt sources, checksum-verified
where upstream publishes one. The two `.deb`s are the exception: they need sudo
for `apt-get install`, so run the script from a real terminal to get them.

| Tool | Source |
|---|---|
| `kubectl` | `dl.k8s.io` (tracks `stable.txt`) |
| `helm` | `get.helm.sh` |
| `stern` | GitHub release |
| `k3d` | GitHub release — **runs the cluster**; the others are only clients |
| `radar` | GitHub release — installs as `kubectl-radar` with a `radar` symlink, matching the Homebrew formula |
| `radar-desktop` | GitHub `.deb`. Its binary is `radar-desktop`, so no clash with the `radar` CLI |
| `freelens` | GitHub `.deb` |

A deliberate subset of [`Brewfile.k8s`](Brewfile.k8s): `k9s`, `eksctl`,
`kubeshark` and `kubectl-ai` are not installed on Linux. `openlens` has been
dropped from the Brewfile entirely — dead upstream since 2023-06-30, superseded
by `freelens`.

> **Docker's ufw bypass applies to k3d.** k3d publishes ports through Docker,
> which reaches the LAN regardless of ufw.
> `scripts/Ubuntu/bin/docker-user-firewall.sh` now contains that by default, and
> k3d's per-network bridges match its trusted `br-+` wildcard so cluster
> networking is unaffected. Binding to loopback (`--api-port 127.0.0.1:6550`,
> `-p 127.0.0.1:8080:80@loadbalancer`) is still the better habit — belt and
> braces, and it does not depend on the chain having been applied.

### Tailscale (opt-in)

```sh
~/.dotfiles/scripts/Ubuntu/install_tailscale.sh
```

Not wired into bootstrap, mirroring `Brewfile.tailscale` and
`scripts/macOS/install_tailscale_app.zsh` on macOS — joining a tailnet is a
per-machine decision.

This is the **one exception** to the no-third-party-apt-repository rule above,
and it is deliberate. Everything in the k8s toolchain is a static Go binary that
drops into `~/.local/bin` with no root; Tailscale is not. The CLI is only half of
it — `tailscaled` is a privileged daemon that opens a TUN device and needs a
systemd unit, so root is unavoidable. Once it is, the signed vendor repo beats a
hand-rolled unit: it keeps a network-exposed daemon on the unattended-upgrade
path. Ubuntu's own `tailscale` in universe lags upstream by a release cycle,
which is the wrong trade here.

| Item | Where it lands |
|---|---|
| repository key | `/usr/share/keyrings/tailscale-archive-keyring.gpg` |
| apt source | `/etc/apt/sources.list.d/tailscale.list`, suite = this box's `lsb_release -cs`, falling back to `plucky` if Tailscale has not packaged the release yet |
| `tailscale`, `tailscaled` | `/usr/bin`, from `pkgs.tailscale.com/stable/ubuntu` |

The script installs the package and runs `systemctl enable --now tailscaled`,
then stops. Joining the tailnet opens a browser login, so it stays manual:

```sh
sudo tailscale up --ssh --accept-routes
```

`--ssh` allows SSH into this box over the tailnet, gated by the tailnet ACLs;
`--accept-routes` consumes subnet routes other nodes advertise. This box
advertises nothing.

> **The tailnet is trusted by the Docker firewall, on purpose.**
> `scripts/Ubuntu/bin/docker-user-firewall.sh` lists `tailscale0` in
> `TRUSTED_IFS`, so your own devices reach published container ports over the
> tailnet while the LAN stays contained. Access control there is the tailnet
> ACLs, not iptables. Drop `tailscale0` from that list to contain it like the LAN.

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
| `~/.cargo/bin` | prepended only when the directory exists (rustup is installed with `--no-modify-path`) |
| pyenv | `$PYENV_ROOT/bin` + `shims` prepended when present; the full `pyenv init` is deferred to first use of `pyenv` |

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
| `Brewfile.apple` / `.aitools` / `.tailscale` / `.netbird` | Further opt-in macOS manifests, applied by their own `scripts/macOS/install_*.zsh` |
| [`PACKAGES.md`](PACKAGES.md) | Human-readable documentation of every tracked Brewfile package, plus where each comes from on Linux |
| `zshrc` | Tracked `~/.zshrc`, shared by macOS and Linux (symlinked into place by `link.zsh` / `link.sh`) |
| `oh-my-zsh/core.sh` | Theme + plugins config sourced before `oh-my-zsh.sh` |
| `aliases/core.sh` | Shared aliases (loaded on every shell) |
| `aliases/<project>.sh` | Per-project aliases auto-loaded by directory |
| `functions/core.sh` | Shared shell functions |
| `functions/project-aliases.sh` | `chpwd` hook that auto-sources project alias files |
| `paths/core.sh` | Extra `PATH` entries |
| `runtimes/claude.sh` | The **only** file under `runtimes/` that `zshrc` sources. The nvm/sdkman/pyenv loaders were inlined into `zshrc`; the remaining `runtimes/*.sh` are unreferenced legacy and several hardcode macOS paths — do not assume they run |
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
| `scripts/Ubuntu/install_k8s_tools.sh` | Opt-in Kubernetes toolchain (not run by bootstrap) |
| `scripts/Ubuntu/install_tailscale.sh` | Opt-in Tailscale install (not run by bootstrap; the only script that adds an apt repository) |
| [`scripts/Ubuntu/bin/`](scripts/Ubuntu/bin/) | Host-maintenance scripts run by hand under sudo, symlinked into `~/bin` by `link.sh`: `docker-user-firewall.sh` (default-deny `DOCKER-USER` containment for Docker's ufw bypass), `ufw-docker-test.sh` (proves it, from an off-box client), `install-docker.sh` |
| [`scripts/Ubuntu/wlheadless-run`](scripts/Ubuntu/wlheadless-run) | Headless-Wayland wrapper — the `xvfb-run` stand-in. The one tracked executable meant for `$PATH`; `link.sh` symlinks it into `~/.local/bin` |
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
