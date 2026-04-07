#!/usr/bin/env bash
# bootstrap.sh — end-to-end setup for cebartling/dotfiles on macOS.
#
# Idempotent: safe to re-run on a Mac that's already partially set up.
# On a brand-new Mac, run with:
#
#   git clone git@github.com:cebartling/dotfiles.git "$HOME/.dotfiles"
#   "$HOME/.dotfiles/bootstrap.sh"

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
REPO_URL="git@github.com:cebartling/dotfiles.git"

# ---------- helpers ----------
say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || die "bootstrap.sh only supports macOS"
}

# ---------- steps ----------

ensure_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    say "Xcode Command Line Tools already installed"
  else
    say "Installing Xcode Command Line Tools (a GUI prompt will appear)"
    xcode-select --install || true
    warn "Re-run bootstrap.sh after the Xcode CLT install completes"
    exit 0
  fi
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    say "Homebrew already installed"
  else
    say "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Ensure brew is on PATH for the rest of this script (Apple Silicon path).
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

ensure_dotfiles_repo() {
  if [[ -d "$DOTFILES/.git" ]]; then
    say "Dotfiles repo already present at $DOTFILES"
  else
    say "Cloning dotfiles repo to $DOTFILES"
    git clone "$REPO_URL" "$DOTFILES"
  fi
}

run_brew_bundle() {
  say "Installing packages from Brewfile (this can take a while on a fresh Mac)"
  brew bundle --file="$DOTFILES/Brewfile"
}

ensure_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    say "oh-my-zsh already installed"
  else
    say "Installing oh-my-zsh (unattended, won't touch ~/.zshrc or login shell)"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

ensure_sdkman() {
  if [[ -d "$HOME/.sdkman" ]]; then
    say "sdkman already installed"
  else
    say "Installing sdkman"
    curl -s "https://get.sdkman.io" | bash
  fi
}

ensure_nvm_dir() {
  # nvm itself is installed via the Brewfile (formula). The lazy-loader
  # in zshrc just needs $NVM_DIR to exist.
  mkdir -p "$HOME/.nvm"
  say "$HOME/.nvm ready"
}

run_link() {
  say "Symlinking dotfiles into place"
  "$DOTFILES/scripts/macOS/link.zsh"
}

print_next_steps() {
  cat <<'EOF'

==> Bootstrap complete.

Next steps:
  1. Open a new terminal tab (or run: exec zsh)
  2. Verify: readlink ~/.zshrc        # -> ~/.dotfiles/zshrc
             readlink ~/.config/starship.toml
             time zsh -i -c exit       # should be ~150ms
  3. First-time logins:
       gh auth login
       sdk version            # initializes sdkman on first call
       nvm install --lts      # installs an LTS node on first call
  4. Optional: install k8s tooling:
       ~/.dotfiles/scripts/macOS/install_k8s_tools.zsh
  5. Optional: install Tailscale GUI app (needs sudo):
       ~/.dotfiles/scripts/macOS/install_tailscale_app.zsh
  6. Optional: per-machine overrides:
       cp ~/.dotfiles/.zshrc.local.example ~/.zshrc.local
       $EDITOR ~/.zshrc.local

EOF
}

# ---------- main ----------
main() {
  require_macos
  ensure_xcode_clt
  ensure_homebrew
  ensure_dotfiles_repo
  run_brew_bundle
  ensure_oh_my_zsh
  ensure_sdkman
  ensure_nvm_dir
  run_link
  print_next_steps
}

main "$@"
