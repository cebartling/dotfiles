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
# package is macOS-only): mole, cliclick, whisperkit-cli, and every `cask` /
# `vscode` entry in the Brewfile.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }

SKIPPED=()

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
  xh
  gh
  pipx
  python3-poetry
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
  say "Updating apt package lists"
  sudo -n true 2>/dev/null || say "sudo password may be required"
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
  if command -v rustup >/dev/null 2>&1; then
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

# ---------- summary ----------

print_summary() {
  echo
  say "Verifying installed tools"
  local missing=()
  for t in zsh starship eza bat fd rg fzf zoxide delta direnv atuin \
           lazygit gh jq yq just glow hyperfine tokei procs dust \
           tmux tree xh http gitleaks pre-commit uv ast-grep bd rtk bun pnpm rustup cargo pyenv weston; do
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
    warn "not on PATH in this shell: ${missing[*]}"
    warn "(~/.local/bin entries appear after you start a new shell)"
  fi
  echo
  say "Finished installing tools on Ubuntu."
}

main() {
  install_apt
  install_shims
  install_snap
  install_uv
  install_watchexec
  install_ast_grep
  install_beads
  install_rtk
  install_bun
  install_pnpm
  install_rustup
  install_pyenv
  print_summary
}

main "$@"
