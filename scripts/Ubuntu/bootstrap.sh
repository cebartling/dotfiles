#!/usr/bin/env bash
# bootstrap.sh — end-to-end setup for cebartling/dotfiles on Ubuntu.
#
# The Linux counterpart to the top-level bootstrap.sh (which is macOS-only).
# Idempotent: safe to re-run on a box that's already partially set up.
# On a brand-new machine, run with:
#
#   git clone git@github.com:cebartling/dotfiles.git "$HOME/.dotfiles"
#   "$HOME/.dotfiles/scripts/Ubuntu/bootstrap.sh"
#
# This does NOT change your login shell — that needs your password, so it's
# left as a manual step (see the next-steps output). Verify the config works
# first; then chsh.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
REPO_URL="git@github.com:cebartling/dotfiles.git"

# ---------- helpers ----------
say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

require_linux() {
  [[ "$(uname -s)" == "Linux" ]] || die "this bootstrap is for Linux; on macOS run $DOTFILES/bootstrap.sh"
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    case "${ID:-}${ID_LIKE:-}" in
      *debian*|*ubuntu*) : ;;
      *) warn "tested on Ubuntu; '${PRETTY_NAME:-unknown}' may need package-name tweaks" ;;
    esac
  fi
}

# ---------- steps ----------

ensure_dotfiles_repo() {
  if [[ -d "$DOTFILES/.git" ]]; then
    say "Dotfiles repo already present at $DOTFILES"
  else
    say "Cloning dotfiles repo to $DOTFILES"
    git clone "$REPO_URL" "$DOTFILES"
  fi
}

run_install_tools() {
  say "Installing CLI tooling (apt/snap; sudo password required)"
  "$DOTFILES/scripts/Ubuntu/install_tools.sh"
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
    return 0
  fi
  say "Installing sdkman"
  # sdkman's installer appends its own init stanza to ~/.zshrc. The tracked
  # zshrc already lazy-loads sdk(), and ~/.zshrc is about to become a symlink
  # into the repo — so if the installer conjures that file into existence,
  # drop it again and let link.sh own the path.
  local had_zshrc=0
  [[ -e "$HOME/.zshrc" || -L "$HOME/.zshrc" ]] && had_zshrc=1
  curl -s "https://get.sdkman.io" | bash
  if (( ! had_zshrc )) && [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    say "Discarding the ~/.zshrc that sdkman created (zshrc lazy-loads sdk already)"
    rm -f "$HOME/.zshrc"
  fi
}

ensure_nvm() {
  # On macOS nvm comes from the Brewfile formula and lives under
  # $HOMEBREW_PREFIX/opt/nvm. There's no such package on Ubuntu, so install
  # nvm proper into $NVM_DIR. PROFILE=/dev/null keeps its installer from
  # appending a sourcing block to ~/.zshrc — the tracked zshrc already has
  # a lazy loader that finds $NVM_DIR/nvm.sh.
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    say "nvm already installed at $NVM_DIR"
    return 0
  fi
  say "Installing nvm into $NVM_DIR"
  mkdir -p "$NVM_DIR"
  PROFILE=/dev/null bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh)"
}

run_install_fonts() {
  "$DOTFILES/scripts/Ubuntu/install_fonts.sh" || warn "font install failed; continuing"
}

run_link() {
  say "Symlinking dotfiles into place"
  "$DOTFILES/scripts/Ubuntu/link.sh"
}

print_next_steps() {
  cat <<'EOF'

==> Bootstrap complete.

Next steps:
  1. Try zsh WITHOUT committing to it yet:
       zsh -i -c exit      # should print nothing
       exec zsh            # look around; `exit` returns you to bash
  2. Verify: readlink ~/.zshrc               # -> ~/.dotfiles/zshrc
             readlink ~/.config/starship.toml
             time zsh -i -c exit             # should be ~150ms
  3. Once it looks right, make zsh your login shell (asks for your password):
       chsh -s /usr/bin/zsh
     then log out and back in, or open a new terminal tab.
  4. Point your terminal at the Nerd Font (from a desktop session):
       gsettings set org.gnome.Ptyxis use-system-font false
       gsettings set org.gnome.Ptyxis font-name 'JetBrainsMono Nerd Font 12'
  5. First-time logins:
       gh auth login
       sdk version            # initializes sdkman on first call
       nvm install --lts      # installs an LTS node on first call
  6. Optional: per-machine overrides:
       cp ~/.dotfiles/.zshrc.local.example ~/.zshrc.local
       $EDITOR ~/.zshrc.local

EOF
}

# ---------- main ----------
main() {
  require_linux
  ensure_dotfiles_repo
  run_install_tools
  ensure_oh_my_zsh
  ensure_sdkman
  ensure_nvm
  run_install_fonts
  run_link
  print_next_steps
}

main "$@"
