#!/usr/bin/env bash
# install_nodejs.sh — system Node.js on Ubuntu, from NodeSource.
#
# Opt-in and NOT wired into bootstrap.sh, like install_chrome.sh and
# install_tailscale.sh — it adds a third-party apt repository and needs sudo.
#
#   ~/.dotfiles/scripts/Ubuntu/install_nodejs.sh
#
# This is a *system* node at /usr/bin/node, for contexts that never load nvm:
# sudo, systemd units, cron, non-interactive scripts. bootstrap.sh still
# installs node via nvm, and in an interactive shell nvm's node wins on $PATH.
#
# NodeSource's setup script writes the keyring, a deb822 source pinned to one
# major line (node_<major>.x), and apt preferences that rank deb.nodesource.com
# above Ubuntu's own older nodejs. Re-running it rewrites all three, so skip it
# when the source for this major is already in place.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

NODE_MAJOR=24
SOURCES="/etc/apt/sources.list.d/nodesource.sources"
SETUP_URL="https://deb.nodesource.com/setup_${NODE_MAJOR}.x"

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Every step below needs root, and a password prompt nobody is there to answer
# just hangs.
require_sudo() {
  sudo -n true 2>/dev/null && return 0
  warn "nodejs needs sudo (apt repository, package install), and sudo is not available non-interactively here."
  die "Run this script from a real terminal."
}

add_repo() {
  if grep -q "node_${NODE_MAJOR}.x" "$SOURCES" 2>/dev/null; then
    say "NodeSource node_${NODE_MAJOR}.x apt repository already configured"
    return 0
  fi
  say "Adding the NodeSource node_${NODE_MAJOR}.x apt repository"
  curl -fsSL "$SETUP_URL" | sudo -E bash - \
    || die "NodeSource setup script failed ($SETUP_URL)"
}

install_nodejs() {
  if dpkg-query -W -f='${Version}' nodejs 2>/dev/null | grep -q nodesource; then
    say "nodejs already installed from NodeSource ($(/usr/bin/node --version))"
    return 0
  fi
  say "Installing nodejs"
  sudo apt-get install -y nodejs
}

require_sudo
add_repo
install_nodejs

echo
say "Installed: /usr/bin/node $(/usr/bin/node --version)"
say "Updates arrive through apt with the rest of the system."
