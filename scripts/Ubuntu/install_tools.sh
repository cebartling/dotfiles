#!/usr/bin/env bash
# install_tools.sh — install the CLI toolchain on Ubuntu.
#
# The Linux counterpart to scripts/macOS/install_tools.zsh. There is no
# Homebrew here: Ubuntu 24.04+ carries almost every formula from the main
# Brewfile in apt, so apt is the source of truth and snap/upstream
# installers fill the four gaps.
#
# Idempotent and non-interactive — safe to re-run.
#
#   ~/.dotfiles/scripts/Ubuntu/install_tools.sh
#
# Deliberately NOT installed on Linux (no Linux distribution exists, or the
# package is macOS-only): mole, cliclick, whisperkit-cli, and every `cask`
# entry in the Brewfile except obsidian, which comes from its vendor .deb.

# --- install-all metadata ---
# Read by install_all.sh. Keep this in sync with any new hard
# precondition added below, or install_all will not know about it.
# summary: The CLI toolchain: apt, snap, and upstream binaries into ~/.local/bin
# group: core
# sudo: required
# --- end metadata ---

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }

SKIPPED=()
HAVE_SUDO=0

# Decide once, up front, whether the root steps can run. Cached sudo: yes. A
# controlling terminal: ask now, once, while a human is plainly present — that
# is /dev/tty, not stdin, because `curl … | bash` has a pipe on stdin and a
# person at the keyboard, and sudo reads the password from /dev/tty anyway.
# Neither (agent, cron, `ssh host cmd`): sudo would fail on the spot and
# `set -e` would end the whole run, so skip every root step and say so.
ensure_sudo() {
  if sudo -n true 2>/dev/null; then HAVE_SUDO=1; return 0; fi
  if { : >/dev/tty; } 2>/dev/null; then
    say "apt, snap and .deb installs need sudo — asking once, now"
    sudo -v && { HAVE_SUDO=1; return 0; }
  fi
  warn "no usable sudo (not cached, no terminal to ask on) — skipping apt, snap and .deb installs; everything under \$HOME still runs."
}

# Every binary that should exist once this script has run. Shared with
# scripts/Ubuntu/doctor.sh — keep additions here, not in either consumer.
VERIFY_TOOLS=(
  zsh starship eza bat fd rg fzf zoxide delta direnv atuin
  lazygit gh acli jq yq just glow hyperfine tokei procs dust
  tmux tree xh http gitleaks pre-commit uv ast-grep bd rtk
  bun pnpm rustup cargo linear-cli pyenv weston
  nmap mlr pgcli pandoc magick ffmpeg fastfetch
  fx doggo grpcurl duckdb cheat cargo-binstall trivy caddy
  semgrep hf tsc typescript-language-server ccusage playwright-cli op
)
# 1Password publishes its desktop app for amd64 only; arm64 gets just `op`.
if [[ "$(uname -m)" == x86_64 ]]; then VERIFY_TOOLS+=(1password); fi

# npm-published CLIs, as "<command>:<package>". Installed with `pnpm add -g`
# into $PNPM_HOME/bin (on $path via zshrc), which — unlike `npm -g` under nvm —
# survives a node version switch, and unlike the system npm needs no root.
NODE_CLIS=(
  tsc:typescript
  typescript-language-server:typescript-language-server
  ccusage:ccusage
  playwright-cli:@playwright/cli
)

# ---------- apt ----------

# Base: shell, plugins, build toolchain, fetchers.
APT_BASE=(
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
  build-essential
  curl
  wget
  unzip
  git
  git-lfs
  openssl
  fontconfig
  net-tools
  ufw
)

# Modern CLI replacements (Brewfile: "Modern CLI replacements").
APT_MODERN=(
  starship
  eza
  bat
  fd-find
  ripgrep
  fzf
  zoxide
  git-delta
  du-dust
  procs
  tree
  tmux
  jq
  yq
)

# Dev tooling (Brewfile: "Dev tooling" + runtimes available in apt).
APT_DEV=(
  direnv
  atuin
  lazygit
  glow
  hyperfine
  just
  tokei
  pre-commit
  gitleaks
  httpie
  mosh
  xh
  gh
  pipx
  python3-poetry
  # PIN-243: Brewfile tools Ubuntu packages at a current version.
  nmap
  miller
  pgcli
  pandoc
  imagemagick
  ffmpeg
  fastfetch
)

# Playwright browser dependencies — the bundled Chromium/Firefox/WebKit
# builds need these shared libraries beyond what `playwright install-deps`
# resolves on 24.04+.
APT_PLAYWRIGHT=(
  libavif16
  libmanette-0.2-0
)

# Headless Wayland display — the xvfb/xvfb-run stand-in for Wayland-native
# clients. weston's headless backend is the display; scripts/Ubuntu/wlheadless-run
# is the xvfb-run half, which nothing packages. wayland-utils supplies
# `wayland-info`, which is how you check the display actually came up.
APT_WAYLAND=(
  weston
  wayland-utils
)

# Build dependencies for pyenv — CPython is compiled from source, and a
# missing header here surfaces much later as a half-built interpreter.
# https://github.com/pyenv/pyenv/wiki#suggested-build-environment
APT_PYENV_BUILD=(
  libssl-dev
  zlib1g-dev
  libbz2-dev
  libreadline-dev
  libsqlite3-dev
  libncursesw5-dev
  xz-utils
  tk-dev
  libxml2-dev
  libxmlsec1-dev
  libffi-dev
  liblzma-dev
)

install_apt() {
  if (( ! HAVE_SUDO )); then SKIPPED+=("apt packages (no sudo)"); return 0; fi
  say "Updating apt package lists"
  sudo apt-get update -qq

  say "Installing apt packages (base, modern CLI, dev tooling)"
  # Recommends are left on deliberately: git/pipx/pre-commit pull in
  # genuinely useful companions, and this is a desktop, not a container.
  sudo apt-get install -y \
    "${APT_BASE[@]}" "${APT_MODERN[@]}" "${APT_DEV[@]}" \
    "${APT_WAYLAND[@]}" "${APT_PYENV_BUILD[@]}" "${APT_PLAYWRIGHT[@]}"
}

# ---------- binary name shims ----------

# Debian/Ubuntu rename two binaries to avoid file clashes with other
# packages: bat -> batcat, fd -> fdfind. The dotfiles aliases and the
# rest of the world expect the upstream names, so shim them into
# ~/.local/bin (already on $path via zshrc).
install_shims() {
  say "Linking batcat/fdfind shims into ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  [[ -x /usr/bin/batcat ]] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
  [[ -x /usr/bin/fdfind ]] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
}

# ---------- snap ----------

install_snap() {
  if ! command -v snap >/dev/null 2>&1; then
    warn "snap not available; skipping vale and difftastic"
    SKIPPED+=("vale (no snap)" "difftastic (no snap)")
    return 0
  fi
  for pkg in vale difftastic; do
    if snap list "$pkg" >/dev/null 2>&1; then
      say "snap $pkg already installed"
    elif (( ! HAVE_SUDO )); then
      SKIPPED+=("$pkg (no sudo)")
    else
      say "Installing snap $pkg"
      sudo snap install "$pkg" || { warn "snap install $pkg failed"; SKIPPED+=("$pkg"); }
    fi
  done
}

# ---------- upstream installers (apt has no package) ----------

install_uv() {
  if command -v uv >/dev/null 2>&1; then
    say "uv already installed"
    return 0
  fi
  # INSTALLER_NO_MODIFY_PATH: uv's installer appends to ".zshrc .zshenv" when
  # its install dir isn't already on PATH. ~/.zshrc is a symlink into this
  # repo, and the tracked zshrc already puts ~/.local/bin on $path.
  say "Installing uv (astral.sh)"
  curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh
}

install_watchexec() {
  if command -v watchexec >/dev/null 2>&1; then
    say "watchexec already installed"
    return 0
  fi
  if (( ! HAVE_SUDO )); then SKIPPED+=("watchexec (no sudo)"); return 0; fi
  say "Installing watchexec (GitHub release .deb)"
  local arch deb url tmp
  case "$(uname -m)" in
    x86_64)  arch="x86_64-unknown-linux-gnu" ;;
    aarch64) arch="aarch64-unknown-linux-gnu" ;;
    *) warn "unsupported arch $(uname -m) for watchexec"; SKIPPED+=("watchexec"); return 0 ;;
  esac
  url="$(curl -fsSL https://api.github.com/repos/watchexec/watchexec/releases/latest \
        | grep -o "https://[^\"]*${arch}\.deb" | head -1)" || true
  if [[ -z "$url" ]]; then
    warn "could not resolve a watchexec .deb download URL"
    SKIPPED+=("watchexec")
    return 0
  fi
  tmp="$(mktemp -d)"
  deb="$tmp/watchexec.deb"
  curl -fsSL -o "$deb" "$url"
  sudo apt-get install -y "$deb"
  rm -rf "$tmp"
}

install_ast_grep() {
  if command -v ast-grep >/dev/null 2>&1; then
    say "ast-grep already installed"
    return 0
  fi
  # `npm install -g` would need root here (npm's prefix is /usr/lib), and
  # repointing npm's global prefix is a bigger footprint than this deserves.
  # Drop the release binary into ~/.local/bin, which is already on $path.
  say "Installing ast-grep (GitHub release binary)"
  local arch url tmp
  case "$(uname -m)" in
    x86_64)  arch="x86_64-unknown-linux-gnu" ;;
    aarch64) arch="aarch64-unknown-linux-gnu" ;;
    *) warn "unsupported arch $(uname -m) for ast-grep"; SKIPPED+=("ast-grep"); return 0 ;;
  esac
  url="$(curl -fsSL https://api.github.com/repos/ast-grep/ast-grep/releases/latest \
        | grep -o "https://[^\"]*app-${arch}\.zip" | head -1)" || true
  if [[ -z "$url" ]]; then
    warn "could not resolve an ast-grep download URL"
    SKIPPED+=("ast-grep")
    return 0
  fi
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/ast-grep.zip" "$url" \
     && unzip -qo "$tmp/ast-grep.zip" -d "$tmp"; then
    mkdir -p "$HOME/.local/bin"
    [[ -f "$tmp/ast-grep" ]] && install -m 0755 "$tmp/ast-grep" "$HOME/.local/bin/ast-grep"
    # The archive also ships the short alias `sg`, but that is the name of the
    # setgid binary from the `login` package on some systems. Only take it if
    # nothing else already owns the name.
    if [[ -f "$tmp/sg" ]] && ! command -v sg >/dev/null 2>&1; then
      install -m 0755 "$tmp/sg" "$HOME/.local/bin/sg"
    elif [[ -f "$tmp/sg" ]]; then
      say "skipping ast-grep's 'sg' alias — $(command -v sg) already exists"
    fi
  else
    warn "ast-grep download/extract failed"
    SKIPPED+=("ast-grep")
  fi
  rm -rf "$tmp"
}

install_beads() {
  if command -v bd >/dev/null 2>&1; then
    say "bd (beads) already installed"
    return 0
  fi
  # beads is a Homebrew formula on macOS (steveyegge/beads tap) but ships
  # plain Linux release tarballs, so no tap machinery is needed here.
  say "Installing bd (beads) from GitHub release"
  local arch url tmp
  case "$(uname -m)" in
    x86_64)  arch="linux_amd64" ;;
    aarch64) arch="linux_arm64" ;;
    *) warn "unsupported arch $(uname -m) for beads"; SKIPPED+=("bd"); return 0 ;;
  esac
  url="$(curl -fsSL https://api.github.com/repos/steveyegge/beads/releases/latest \
        | grep -o "https://[^\"]*_${arch}\.tar\.gz" | head -1)" || true
  if [[ -z "$url" ]]; then
    warn "could not resolve a beads download URL"
    SKIPPED+=("bd")
    return 0
  fi
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/beads.tar.gz" "$url" && tar -xzf "$tmp/beads.tar.gz" -C "$tmp"; then
    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$tmp/bd" "$HOME/.local/bin/bd"
  else
    warn "beads download/extract failed"
    SKIPPED+=("bd")
  fi
  rm -rf "$tmp"
}

install_rtk() {
  if command -v rtk >/dev/null 2>&1; then
    say "rtk already installed"
    return 0
  fi
  # Rust Token Killer — upstream is rtk-ai/rtk (NOT the unrelated npm package
  # named `rtk`, which is a changelog/release tool). Homebrew has it on macOS;
  # upstream ships a .deb for Linux.
  say "Installing rtk (Rust Token Killer) from GitHub release"
  local url tmp
  if [[ "$(uname -m)" != "x86_64" ]]; then
    warn "rtk .deb is amd64 only; skipping on $(uname -m)"
    SKIPPED+=("rtk")
    return 0
  fi
  url="$(curl -fsSL https://api.github.com/repos/rtk-ai/rtk/releases/latest \
        | grep -o "https://[^\"]*rtk_amd64\.deb" | head -1)" || true
  if [[ -z "$url" ]]; then
    warn "could not resolve an rtk download URL"
    SKIPPED+=("rtk")
    return 0
  fi
  tmp="$(mktemp -d)"
  # Unpack rather than `apt-get install ./rtk.deb`: the payload is a single
  # binary, and ~/.local/bin keeps it consistent with the other shims here.
  if curl -fsSL -o "$tmp/rtk.deb" "$url" && dpkg-deb -x "$tmp/rtk.deb" "$tmp/x"; then
    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$tmp/x/usr/bin/rtk" "$HOME/.local/bin/rtk"
  else
    warn "rtk download/extract failed"
    SKIPPED+=("rtk")
  fi
  rm -rf "$tmp"
}

install_acli() {
  if command -v acli >/dev/null 2>&1; then
    say "acli (Atlassian CLI) already installed"
    return 0
  fi
  # Homebrew reaches this through the atlassian-labs/acli tap on macOS. There
  # is no apt package and no GitHub repo to query — Atlassian publishes the
  # binary straight from acli.atlassian.com under a stable /latest/ path, so
  # there is no release JSON to grep for a URL here.
  #
  # The same path also offers a .deb, but the payload is one binary and
  # ~/.local/bin needs no root. Take the bare ELF and skip dpkg entirely.
  say "Installing acli (Atlassian CLI) from acli.atlassian.com"
  local arch url tmp
  case "$(uname -m)" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    *) warn "unsupported arch $(uname -m) for acli"; SKIPPED+=("acli"); return 0 ;;
  esac
  url="https://acli.atlassian.com/linux/latest/acli_linux_${arch}/acli"
  tmp="$(mktemp -d)"
  # A bad path here returns an XML error document with a 200-ish shape rather
  # than a hard 404, so -f alone will not catch it. Check for the ELF magic
  # before installing anything.
  if curl -fsSL -o "$tmp/acli" "$url" \
     && [[ "$(head -c 4 "$tmp/acli" | od -An -tx1 | tr -d ' \n')" == "7f454c46" ]]; then
    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$tmp/acli" "$HOME/.local/bin/acli"
    say "acli installed; run 'acli jira auth login' to authenticate"
  else
    warn "acli download failed or did not return a Linux binary"
    SKIPPED+=("acli")
  fi
  rm -rf "$tmp"
}

install_linear_cli() {
  # Must run after install_rustup. cargo is not on this process's PATH when
  # rustup was installed moments ago, so resolve it out of ~/.cargo/bin
  # directly rather than trusting `command -v cargo`.
  local cargo_bin="$HOME/.cargo/bin/cargo"
  if [[ -x "$HOME/.cargo/bin/linear-cli" ]] || command -v linear-cli >/dev/null 2>&1; then
    say "linear-cli already installed"
    return 0
  fi
  if [[ ! -x "$cargo_bin" ]]; then
    warn "cargo not found at $cargo_bin; skipping linear-cli"
    SKIPPED+=("linear-cli")
    return 0
  fi
  # The Brewfile installs this the same way (cargo "linear-cli"), so both
  # platforms build the identical crates.io crate. There are no prebuilt
  # binaries upstream, which is why this compiles rather than downloads.
  say "Installing linear-cli (cargo install — this compiles from source)"
  if "$cargo_bin" install linear-cli; then
    say "linear-cli installed to ~/.cargo/bin"
  else
    warn "cargo install linear-cli failed"
    SKIPPED+=("linear-cli")
  fi
}

install_bun() {
  if command -v bun >/dev/null 2>&1; then
    say "bun already installed"
    return 0
  fi
  # Brewfile installs bun via the oven-sh/bun tap on macOS. On Linux the
  # official installer (bun.sh/install) appends its own block to ~/.zshrc —
  # which is a symlink into this repo — so take the release zip instead.
  say "Installing bun from GitHub release"
  local variant url tmp
  case "$(uname -m)" in
    x86_64)
      # The default x64 build requires AVX2; older CPUs need the baseline build.
      if grep -qm1 '\bavx2\b' /proc/cpuinfo 2>/dev/null; then
        variant="bun-linux-x64"
      else
        say "no AVX2 on this CPU — using the baseline build"
        variant="bun-linux-x64-baseline"
      fi
      ;;
    aarch64) variant="bun-linux-aarch64" ;;
    *) warn "no bun build for $(uname -m)"; SKIPPED+=("bun"); return 0 ;;
  esac
  # Match the exact asset name: the -profile variants are large debug builds.
  url="$(curl -fsSL https://api.github.com/repos/oven-sh/bun/releases/latest \
        | grep -o "https://[^\"]*/${variant}\.zip" | head -1)" || true
  if [[ -z "$url" ]]; then
    warn "could not resolve a bun download URL for ${variant}"
    SKIPPED+=("bun")
    return 0
  fi
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/bun.zip" "$url" && unzip -qo "$tmp/bun.zip" -d "$tmp"; then
    local bin
    bin="$(find "$tmp" -type f -name bun -perm -u+x | head -1)"
    if [[ -n "$bin" ]]; then
      mkdir -p "$HOME/.local/bin"
      install -m 0755 "$bin" "$HOME/.local/bin/bun"
      # bun's own installer provides bunx as a link to the same binary.
      ln -sf bun "$HOME/.local/bin/bunx"
    else
      warn "no bun binary inside the archive"
      SKIPPED+=("bun")
    fi
  else
    warn "bun download/extract failed"
    SKIPPED+=("bun")
  fi
  rm -rf "$tmp"
}

install_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    say "pnpm already installed"
    return 0
  fi
  # `curl get.pnpm.io/install.sh | sh` runs `pnpm setup`, which appends a
  # PNPM_HOME block to ~/.zshrc — that file is a symlink into this repo. The
  # tracked zshrc already exports PNPM_HOME and puts it on $path, so take the
  # standalone release instead.
  #
  # The archive is a tree, not a lone binary: a `pnpm` launcher that resolves
  # its own realpath to find a sibling `dist/`. Install the whole thing under
  # ~/.local/lib and symlink just the launcher onto PATH.
  say "Installing pnpm from GitHub release"
  local variant url tmp dest
  case "$(uname -m)" in
    x86_64)  variant="pnpm-linux-x64" ;;
    aarch64) variant="pnpm-linux-arm64" ;;
    *) warn "no pnpm build for $(uname -m)"; SKIPPED+=("pnpm"); return 0 ;;
  esac
  # Anchor to .tar.gz so the -musl variant of the same stem isn't matched.
  url="$(curl -fsSL https://api.github.com/repos/pnpm/pnpm/releases/latest \
        | grep -o "https://[^\"]*/${variant}\.tar\.gz" | head -1)" || true
  if [[ -z "$url" ]]; then
    warn "could not resolve a pnpm download URL for ${variant}"
    SKIPPED+=("pnpm")
    return 0
  fi
  tmp="$(mktemp -d)"
  dest="$HOME/.local/lib/pnpm"
  if curl -fsSL -o "$tmp/pnpm.tgz" "$url" && tar -xzf "$tmp/pnpm.tgz" -C "$tmp"; then
    if [[ -x "$tmp/pnpm" && -d "$tmp/dist" ]]; then
      rm -rf "$dest"
      mkdir -p "$dest" "$HOME/.local/bin" "${PNPM_HOME:-$HOME/.local/share/pnpm}"
      cp -R "$tmp/pnpm" "$tmp/dist" "$dest/"
      ln -sf "$dest/pnpm" "$HOME/.local/bin/pnpm"
    else
      warn "unexpected pnpm archive layout (no launcher + dist/)"
      SKIPPED+=("pnpm")
    fi
  else
    warn "pnpm download/extract failed"
    SKIPPED+=("pnpm")
  fi
  rm -rf "$tmp"
}

install_rustup() {
  # Check the install path, not just $PATH. ~/.cargo/bin is put on $path by
  # zshrc alone — unlike ~/.local/bin, which Debian's ~/.profile also adds —
  # so `command -v rustup` misses under any non-zsh shell and this re-ran the
  # whole rustup installer on a box that already had it. Harmless (the
  # toolchain came back "unchanged") but a ~300MB no-op. Same reason
  # install_linear_cli resolves cargo by path.
  if [[ -x "$HOME/.cargo/bin/rustup" ]] || command -v rustup >/dev/null 2>&1; then
    say "rustup already installed"
    return 0
  fi
  # --no-modify-path: rustup-init would otherwise append a ~/.cargo/env source
  # line to ~/.zshrc (this repo's tracked zshrc). That file puts
  # ~/.cargo/bin on $path itself when the directory exists.
  say "Installing rustup + the stable toolchain (this pulls ~300MB)"
  if curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
       | sh -s -- -y --no-modify-path --default-toolchain stable --profile default; then
    say "rustup installed; ~/.cargo/bin is picked up by zshrc on next shell"
  else
    warn "rustup install failed"
    SKIPPED+=("rustup")
  fi
}

install_pyenv() {
  if [[ -d "${PYENV_ROOT:-$HOME/.pyenv}" ]]; then
    say "pyenv already installed"
    return 0
  fi
  # pyenv-installer clones pyenv plus the virtualenv/update/doctor plugins and
  # only *prints* shell-config instructions — it writes no profile itself, so
  # no opt-out flag is needed here. The tracked zshrc owns the wiring.
  say "Installing pyenv (+ virtualenv/update/doctor plugins)"
  if curl -fsSL https://pyenv.run | bash; then
    say "pyenv installed; zshrc puts its shims on \$path on the next shell"
  else
    warn "pyenv install failed"
    SKIPPED+=("pyenv")
  fi
}

# ---------- GitHub release binaries (generic) ----------

# install_release <cmd> <owner/repo> <amd64-asset-regex> <arm64-asset-regex>
#
# For tools whose release is one binary: bare, .gz, .tar.gz/.tgz or .zip. The
# regex must match the whole asset file name (ERE); it is anchored to the end
# of the download URL so a .sha256 or .sig next to it cannot match. The binary
# named <cmd> is found anywhere in the archive, checked to be an ELF (a
# rate-limit page or an HTML error must never be installed), and dropped into
# ~/.local/bin. The hand-written installers above predate this and each have a
# quirk (a .deb, an alias, a launcher tree) this deliberately does not model.
install_release() {
  local cmd="$1" repo="$2" pat url asset tmp bin
  if command -v "$cmd" >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/$cmd" ]]; then
    say "$cmd already installed"
    return 0
  fi
  case "$(uname -m)" in
    x86_64)  pat="$3" ;;
    aarch64) pat="$4" ;;
    *) warn "unsupported arch $(uname -m) for $cmd"; SKIPPED+=("$cmd"); return 0 ;;
  esac
  url="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | grep -oE "\"https://[^\"]*/${pat}\"" | tr -d '"' | head -1)" || true
  if [[ -z "$url" ]]; then
    warn "could not resolve a $cmd download URL from $repo"
    SKIPPED+=("$cmd")
    return 0
  fi
  say "Installing $cmd (GitHub release: ${url##*/})"
  asset="${url##*/}"
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/x"
  if curl -fsSL -o "$tmp/$asset" "$url"; then
    case "$asset" in
      *.tar.gz|*.tgz) tar -xzf "$tmp/$asset" -C "$tmp/x" ;;
      *.zip)          unzip -qo "$tmp/$asset" -d "$tmp/x" ;;
      *.gz)           gunzip -c "$tmp/$asset" > "$tmp/x/$cmd" ;;
      *)              cp "$tmp/$asset" "$tmp/x/$cmd" ;;
    esac
    bin="$(find "$tmp/x" -type f -name "$cmd" | head -1)"
  fi
  if [[ -n "${bin:-}" && "$(head -c 4 "$bin" | od -An -tx1 | tr -d ' \n')" == "7f454c46" ]]; then
    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$bin" "$HOME/.local/bin/$cmd"
  else
    warn "$cmd download/extract failed, or no Linux binary named '$cmd' in ${asset}"
    SKIPPED+=("$cmd")
  fi
  rm -rf "$tmp"
}

# PIN-243. Asset names checked against each project's latest release for both
# architectures; duckdb takes the glibc build, cargo-binstall the slim one.
install_release_tools() {
  install_release fx             antonmedv/fx          'fx_linux_amd64'                                 'fx_linux_arm64'
  install_release doggo          mr-karan/doggo        'doggo-linux-x86_64\.tar\.gz'                     'doggo-linux-aarch64\.tar\.gz'
  install_release grpcurl        fullstorydev/grpcurl  'grpcurl_[0-9.]+_linux_x86_64\.tar\.gz'           'grpcurl_[0-9.]+_linux_arm64\.tar\.gz'
  install_release duckdb         duckdb/duckdb         'duckdb_cli-linux-amd64\.gz'                      'duckdb_cli-linux-arm64\.gz'
  install_release cheat          cheat/cheat           'cheat-linux-amd64\.gz'                           'cheat-linux-arm64\.gz'
  install_release cargo-binstall cargo-bins/cargo-binstall 'cargo-binstall-x86_64-unknown-linux-gnu\.tgz' 'cargo-binstall-aarch64-unknown-linux-gnu\.tgz'
  install_release trivy          aquasecurity/trivy    'trivy_[0-9.]+_Linux-64bit\.tar\.gz'              'trivy_[0-9.]+_Linux-ARM64\.tar\.gz'
  # The release binary, not Ubuntu's caddy package: that one is years older and
  # enables a caddy.service listening on :80. This is the CLI only.
  install_release caddy          caddyserver/caddy     'caddy_[0-9.]+_linux_amd64\.tar\.gz'              'caddy_[0-9.]+_linux_arm64\.tar\.gz'
}

# ---------- uv tools ----------

# Python CLIs, each in its own uv-managed environment, bins in ~/.local/bin.
# `uv tool install` writes no shell profile (`uv tool update-shell` would; it is
# never run). uv by absolute path: this process's PATH predates install_uv.
install_uv_tools() {
  local uv pair cmd spec
  uv="$(command -v uv 2>/dev/null || echo "$HOME/.local/bin/uv")"
  if [[ ! -x "$uv" ]]; then
    SKIPPED+=("semgrep hf (no uv)")
    return 0
  fi
  for pair in semgrep:semgrep hf:huggingface_hub; do
    cmd="${pair%%:*}"; spec="${pair#*:}"
    if command -v "$cmd" >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/$cmd" ]]; then
      say "$cmd already installed"
      continue
    fi
    say "Installing $cmd (uv tool install $spec)"
    "$uv" tool install "$spec" || { warn "uv tool install $spec failed"; SKIPPED+=("$cmd"); }
  done
}

# ---------- node CLIs (pnpm global) ----------

# Needs a node: the packages may run install scripts. On a fresh bootstrap
# this script runs before any node exists, so it skips here and bootstrap.sh
# calls `install_tools.sh --node-clis` again once nvm's node is in.
install_node_clis() {
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"   # as zshrc
  # pnpm 11+ puts global bins in $PNPM_HOME/bin and refuses `add -g` unless
  # that is on PATH (its fix, `pnpm setup`, would edit ~/.zshrc — this repo).
  PATH="$PNPM_HOME/bin:$PNPM_HOME:$HOME/.local/bin:$PATH"
  local pair cmd node_bin missing=()
  if ! command -v pnpm >/dev/null 2>&1; then
    SKIPPED+=("node CLIs (no pnpm)")
    return 0
  fi
  if ! command -v node >/dev/null 2>&1; then
    node_bin="$(compgen -G "$HOME/.nvm/versions/node/v*/bin/node" | sort -V | tail -1 || true)"
    [[ -z "$node_bin" && -x /usr/bin/node ]] && node_bin=/usr/bin/node
    if [[ -z "$node_bin" ]]; then
      SKIPPED+=("node CLIs (no node yet; bootstrap re-runs this with --node-clis)")
      return 0
    fi
    PATH="$(dirname "$node_bin"):$PATH"
  fi
  for pair in "${NODE_CLIS[@]}"; do
    cmd="${pair%%:*}"
    if [[ -x "$PNPM_HOME/bin/$cmd" ]] || command -v "$cmd" >/dev/null 2>&1; then
      say "$cmd already installed"
    else
      missing+=("${pair#*:}")
    fi
  done
  (( ${#missing[@]} )) || return 0
  say "Installing ${missing[*]} (pnpm add -g, into \$PNPM_HOME)"
  mkdir -p "$PNPM_HOME"
  pnpm add -g "${missing[@]}" || { warn "pnpm add -g failed"; SKIPPED+=("node CLIs"); }
}

# ---------- 1Password (vendor apt repository, needs sudo) ----------

# The CLI everywhere, the desktop app on amd64 (1Password publishes no arm64
# app package). The source is written as the deb822 1password.sources, with
# the keyring at /usr/share/keyrings/1password-archive-keyring.gpg, because
# that is exactly what the `1password` package's postinst manages: on install
# it comments out a 1password.list (observed on lab02, 2026-09-18) and writes
# this .sources itself. Writing the same file means one source from the start
# and nothing left behind. An older box with the .list is still recognised.
install_1password() {
  local arch key src tmp p pkgs=(1password-cli) missing=()
  arch="$(dpkg --print-architecture)"
  key=/usr/share/keyrings/1password-archive-keyring.gpg
  src=/etc/apt/sources.list.d/1password.sources
  if [[ "$arch" == amd64 ]]; then pkgs+=(1password); else SKIPPED+=("1password app (no $arch package)"); fi
  for p in "${pkgs[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p"); done
  if (( ${#missing[@]} == 0 )); then
    say "1password already installed (${pkgs[*]})"
    return 0
  fi
  if (( ! HAVE_SUDO )); then SKIPPED+=("${missing[@]/%/ (no sudo)}"); return 0; fi
  if [[ ! -s "$key" ]] || [[ ! -s "$src" && ! -s /etc/apt/sources.list.d/1password.list ]]; then
    say "Adding 1Password's apt repository"
    tmp="$(mktemp -d)"
    if ! curl -fsSL -o "$tmp/1password.asc" https://downloads.1password.com/linux/keys/1password.asc \
       || ! grep -q 'BEGIN PGP PUBLIC KEY BLOCK' "$tmp/1password.asc"; then
      warn "could not fetch 1Password's signing key (or it was not a PGP key); not adding the repository"
      SKIPPED+=("${missing[@]}")
      rm -rf "$tmp"
      return 0
    fi
    sudo gpg --dearmor --yes --output "$key" "$tmp/1password.asc"
    rm -rf "$tmp"
    sudo tee "$src" >/dev/null <<SRC
Types: deb
URIs: https://downloads.1password.com/linux/debian/$arch
Suites: stable
Components: main
Architectures: $arch
Signed-By: $key
SRC
    sudo apt-get update -qq
  fi
  say "Installing ${missing[*]}"
  sudo apt-get install -y "${missing[@]}" || { warn "1password install failed"; SKIPPED+=("${missing[@]}"); }
}

# ---------- summary ----------

# ---------- GUI apps (vendor .deb, needs sudo) ----------

install_obsidian() {
  if dpkg -s obsidian >/dev/null 2>&1; then
    say "obsidian already installed ($(dpkg-query -W -f='${Version}' obsidian))"
    return 0
  fi
  local arch
  arch="$(dpkg --print-architecture)"
  if [[ "$arch" != amd64 ]]; then
    warn "obsidian publishes an amd64 .deb only; skipping on $arch"
    SKIPPED+=("obsidian (no $arch .deb)")
    return 0
  fi
  # Not releases/latest: a release can ship without desktop builds (v1.13.8
  # carried only the Android .apk), so take the newest release that has a
  # .deb. Obsidian publishes no checksum file; GitHub's per-asset sha256
  # digest stands in for one.
  local asset url digest tmp
  asset="$(curl -fsSL 'https://api.github.com/repos/obsidianmd/obsidian-releases/releases?per_page=10' \
        | jq -r '[.[].assets[] | select(.name | endswith("_amd64.deb"))][0]
                 | "\(.browser_download_url) \(.digest // "")"')" || true
  url="${asset%% *}"
  digest="${asset#* }"; digest="${digest#sha256:}"
  if [[ -z "$url" || "$url" == null ]]; then
    warn "could not resolve an obsidian .deb download URL"; SKIPPED+=(obsidian); return 0
  fi
  if [[ -z "$digest" ]]; then
    warn "no sha256 digest published for ${url##*/}; not installing unverified"; SKIPPED+=(obsidian); return 0
  fi
  # Check for usable sudo first — no point pulling ~116MB to fail at the last step.
  if (( ! HAVE_SUDO )); then
    SKIPPED+=("obsidian (no sudo)")
    return 0
  fi
  say "Installing obsidian (${url##*/}, ~116MB; needs sudo)"
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/obsidian.deb" "$url"; then
    if echo "$digest  $tmp/obsidian.deb" | sha256sum -c --quiet -; then
      sudo apt-get install -y "$tmp/obsidian.deb" || { warn "obsidian install failed"; SKIPPED+=(obsidian); }
    else
      warn "checksum mismatch for ${url##*/}; not installing"; SKIPPED+=(obsidian)
    fi
  else
    warn "obsidian download failed"; SKIPPED+=(obsidian)
  fi
  rm -rf "$tmp"
}

print_summary() {
  echo
  say "Verifying installed tools"
  # This bash process inherited its PATH before any of the installs above ran,
  # so a tool just dropped into ~/.local/bin or ~/.cargo/bin would report as
  # missing here even though it is installed and works in the next shell.
  # pyenv is never on $path at all: zshrc exposes it as a lazy-loading function
  # wrapping $PYENV_ROOT/bin/pyenv. Resolve against the install locations so
  # only a genuine failure is reported.
  local PATH="$HOME/.local/bin:$HOME/.cargo/bin:${PYENV_ROOT:-$HOME/.pyenv}/bin:${PNPM_HOME:-$HOME/.local/share/pnpm}/bin:$PATH"
  local missing=()
  for t in "${VERIFY_TOOLS[@]}"; do
    if command -v "$t" >/dev/null 2>&1; then
      printf '  \033[32mok\033[0m      %s\n' "$t"
    else
      printf '  \033[31mmissing\033[0m %s\n' "$t"
      missing+=("$t")
    fi
  done

  if (( ${#SKIPPED[@]} )); then
    echo
    warn "skipped: ${SKIPPED[*]}"
  fi
  if (( ${#missing[@]} )); then
    echo
    warn "not installed: ${missing[*]}"
  fi
  if [[ -x /usr/bin/1password ]]; then
    echo
    say "To let 'op' unlock through the desktop app: 1Password -> Settings -> Developer -> Integrate with 1Password CLI"
  fi
  echo
  say "Finished installing tools on Ubuntu."
}

main() {
  # bootstrap.sh calls this once nvm's node exists; the full run before it
  # found no node and skipped the node CLIs. Nothing else, no sudo needed.
  if [[ "${1:-}" == --node-clis ]]; then
    install_node_clis
    (( ${#SKIPPED[@]} )) && warn "skipped: ${SKIPPED[*]}"
    return 0
  fi
  ensure_sudo
  install_apt
  install_shims
  install_snap
  install_uv
  install_uv_tools
  install_watchexec
  install_ast_grep
  install_beads
  install_rtk
  install_acli
  install_bun
  install_pnpm
  install_node_clis
  install_rustup
  install_linear_cli
  install_pyenv
  install_release_tools
  install_obsidian
  install_1password
  print_summary
}

# Only install when run directly. scripts/Ubuntu/doctor.sh sources this file to
# reuse the package arrays below as its single source of truth, and must not
# kick off an install by doing so.
# ${BASH_SOURCE[0]:-} rather than ${BASH_SOURCE[0]}: this file sets -u, and
# BASH_SOURCE does not exist in a non-bash shell, so sourcing it from zsh —
# which is the login shell on these boxes — aborted here instead of just
# defining the functions. Unset means "not sourced from bash", which is not
# the direct-execution case, so the guard correctly declines to install.
if [[ "${BASH_SOURCE[0]:-}" == "$0" ]]; then
  main "$@"
fi
