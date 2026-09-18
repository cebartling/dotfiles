# Ubuntu install scripts

These scripts depend on each other. Until `install_all.sh` existed, those
dependencies lived only in prose headers and in the call order of
`bootstrap.sh:main()` — nothing enforced them, and nothing told you the order.

Each script now carries an `install-all metadata` block. `install_all.sh` parses
those blocks, proves the run order satisfies them, and runs what you pick.

```bash
./install_all.sh                    # prompt for each optional installer
./install_all.sh --list             # the catalog, changes nothing
./install_all.sh --dry-run --all    # what would run, in order
./install_all.sh --only=tailscale,claude_code
./install_all.sh --check            # validate metadata vs ORDER
```

## The catalog

| Script | Group | Sudo | Needs | Depends on |
|---|---|---|---|---|
| `install_tools.sh` | core | required | — | — |
| `install_nodejs.sh` | core | required | — | wants `install_tools.sh` |
| `install_fonts.sh` | core | none | `fc-cache` | wants `install_tools.sh` |
| `link.sh` | core | none | — | — |
| `install_chrome.sh` | opt-in | required | `gpg`, x86_64 | — |
| `install_tailscale.sh` | opt-in | required | `systemctl` | wants `install_tools.sh`, `link.sh` |
| `install_docker.sh` | opt-in | required | `systemctl` | wants `link.sh` |
| `install_k8s_tools.sh` | opt-in | optional | x86_64 | wants `install_tools.sh`, `link.sh`, `install_docker.sh` |
| `install_claude_code.sh` | opt-in | none | — | wants `install_tools.sh` |
| `install_zed.sh` | opt-in | none | — | wants `link.sh` |
| `install_obsidian_headless.sh` | opt-in | optional | `systemctl` | **requires** `install_nodejs.sh` |
| `install_mosh_server.sh` | **dangerous** | required | `ufw` | wants `install_tailscale.sh` |

`requires:` is a hard edge — the script dies or cannot work without it.
`wants:` is a soft edge — it runs, but degrades: skipped firewall rules, missing
glyphs, a slower download.

`install_obsidian_headless.sh` is the only true `requires:` in the directory. It
dies with `no system node at /usr/bin/node` because it needs the *system* node
from `install_nodejs.sh`, not nvm's.

## Groups

- **core** — run unconditionally by `bootstrap.sh`, in that script's own careful
  order (see below). Not offered at the prompt.
- **opt-in** — offered by `install_all.sh`, included by `--all`.
- **dangerous** — offered at the prompt with a warning, but **never** included by
  `--all`. Only `install_mosh_server.sh` is in this group: it runs
  `sudo ufw --force enable`. Its own message says the allows are already in place
  so it cannot lock you out, and that is true *of the rules it wrote* — but on a
  box reached over a non-standard SSH port, or with Docker or WireGuard rules it
  knows nothing about, enabling a firewall remotely can cut the session it is
  running in. This repo ships `bin/docker-user-firewall.sh` and
  `bin/ufw-docker-test.sh` precisely because ufw and Docker interact badly.
  Reach it deliberately: `./install_all.sh --only=mosh_server`.

## Why bootstrap.sh still runs the core four itself

`bootstrap.sh:main()` interleaves script calls with inline functions, and one
ordering constraint is load-bearing:

```
HAD_ZSHRC snapshot          <- must precede every installer
  install_tools.sh
  install_nodejs.sh
  ensure_oh_my_zsh          <- writes ~/.zshrc
  ensure_sdkman             <- appends to ~/.zshrc
  ensure_nvm / ensure_node
  install_fonts.sh
  discard_generated_zshrc   <- MUST follow the profile writers,
  link.sh                      and MUST precede link.sh
  install_all.sh            <- the optional extras, prompted
```

`discard_generated_zshrc` exists because oh-my-zsh and sdkman both write a
`~/.zshrc` that `link.sh` would otherwise back up, leaving a stray
`.backup.<timestamp>` on every fresh machine. Rather than move that sequence into
the orchestrator, `bootstrap.sh` exports `DOTFILES_BOOTSTRAP_ACTIVE=1` and
`install_all.sh` records the core scripts as already done — so `requires:` still
resolves, nothing runs twice, and the fragile part is not disturbed.

Run standalone, `install_all.sh` will run the core scripts itself when something
selected requires them.

## Unattended runs

With **no terminal and no explicit flag**, `install_all.sh` prints an advisory and
exits 0 without changing anything. A piped or SSH `bootstrap.sh` therefore behaves
exactly as it did before this script existed.

Both stdin and stdout must be a TTY before it will prompt: `curl … | bash` leaves
stdout a terminal but stdin a pipe, and `cmd > log` leaves stdin a terminal with
nobody reading the menu. `CI` being set also suppresses prompting.

To select non-interactively:

```bash
DOTFILES_INSTALL_ALL=all ./install_all.sh
DOTFILES_INSTALL_ALL=tailscale,claude_code ./install_all.sh
./install_all.sh --only=tailscale --yes
```

## Sudo

`sudo` is password-prompted on these boxes and unavailable to an agent. The
orchestrator asks **once**, up front, after selection — not six times mid-run —
and refreshes the timestamp between scripts, because a 633-line installer will
outlive the 15-minute default.

With no passwordless sudo and no human to ask, every `sudo: required` script is
dropped into `skipped:` rather than left sitting on a password prompt.

The core path follows the same rule (PIN-245). `install_tools.sh` decides once,
up front: cached sudo is used; with a controlling terminal it asks once, there
and then; with neither — an agent, cron, `ssh host cmd` — its apt, snap and
`.deb` steps land in `skipped:` and everything under `$HOME` still runs.
`bootstrap.sh` only refreshes sudo when it has a terminal to ask on. The test is
`/dev/tty`, not stdin: `curl … | bash` has a pipe on stdin but a person at the
keyboard, and sudo reads the password from the terminal either way. Before this,
sudo with no terminal failed on the spot and `set -e` ended the whole bootstrap
at its first step.

## External prerequisites nothing here installs

- **`gpg`** — `install_chrome.sh` dearmors Google's signing key with it. Ships
  with Ubuntu.
- **`systemd`** — `install_tailscale.sh`, `install_docker.sh` and
  `install_obsidian_headless.sh` all die without `systemctl`.
- **x86_64** — `install_chrome.sh` (Google publishes no arm64 Chrome for Linux)
  and `install_k8s_tools.sh`. `needs-arch` filters these out of the menu entirely
  on other architectures rather than failing at runtime.
- **Docker** — `install_k8s_tools.sh` warns if `docker info` fails; k3d needs it.
  Install it with `install_docker.sh`, which `install_all.sh` orders first.

`ufw` used to be on this list. `install_mosh_server.sh` dies without it and
nothing installed it — it was masked by Ubuntu shipping it by default. It is now
in `install_tools.sh`'s `APT_BASE`, and `needs-cmd: ufw` makes its absence a
skip with a message rather than a mid-run death.

## Adding a script

1. Write it, following the conventions in the existing ones: `set -euo pipefail`,
   the `say`/`warn`/`die` three-liner copied verbatim (there is deliberately no
   shared library on the Linux side), a `command -v` guard so it is idempotent,
   and a `SKIPPED=()` summary.
2. Add an `install-all metadata` block.
3. Add it to `ORDER` in `install_all.sh`, after everything it depends on.
4. Run `./install_all.sh --check`. It fails loudly if `ORDER` and the metadata
   disagree, if a dependency does not exist, or if a script has metadata but no
   place in `ORDER`.

`--check` belongs alongside `bash -n` as a pre-commit gate, and works on macOS
too — it only reads metadata.

> The validator proves `ORDER` satisfies the *declared* edges. It cannot prove
> the declarations match reality: if you add a `die "needs X"` to a script and
> forget `needs-cmd: X`, you are back to a mid-run abort. Update the metadata
> alongside any new hard precondition.
