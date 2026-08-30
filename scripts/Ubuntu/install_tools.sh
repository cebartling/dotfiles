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
# package is macOS-only): rtk, mole, cliclick, whisperkit-cli, and every
# `cask` / `vscode` entry in the Brewfile. Note the npm package named `rtk`
# is an unrelated release tool, not the Rust Token Killer — don't install it.

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

install_apt() {
  say "Updating apt package lists"
  sudo -n true 2>/dev/null || say "sudo password may be required"
  sudo apt-get update -qq

  say "Installing apt packages (base, modern CLI, dev tooling)"
  # Recommends are left on deliberately: git/pipx/pre-commit pull in
  # genuinely useful companions, and this is a desktop, not a container.
  sudo apt-get install -y \
    "${APT_BASE[@]}" "${APT_MODERN[@]}" "${APT_DEV[@]}"
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
  say "Installing uv (astral.sh)"
  curl -LsSf https://astral.sh/uv/install.sh | sh
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

# ---------- summary ----------

print_summary() {
  echo
  say "Verifying installed tools"
  local missing=()
  for t in zsh starship eza bat fd rg fzf zoxide delta direnv atuin \
           lazygit gh jq yq just glow hyperfine tokei procs dust \
           tmux tree xh http gitleaks pre-commit uv ast-grep bd; do
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
  print_summary
}

main "$@"
