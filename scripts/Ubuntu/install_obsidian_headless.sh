#!/usr/bin/env bash
# install_obsidian_headless.sh — headless Obsidian Sync on Ubuntu.
#
# Opt-in and NOT wired into bootstrap.sh: it needs an Obsidian Sync
# subscription, and every vault is a per-machine decision. For boxes reached
# mostly over SSH, where the desktop app is never open to sync.
#
#   ~/.dotfiles/scripts/Ubuntu/install_obsidian_headless.sh
#
# Installs `ob` (npm: obsidian-headless, from obsidianmd) into ~/.local with the
# SYSTEM node from install_nodejs.sh, not nvm's. The systemd unit runs it with
# /usr/bin/node, and better-sqlite3 is a native module built against whichever
# node runs the install, so both must be the same one. nvm's path also changes
# with every upgrade, which a unit file cannot follow.
#
# The unit itself, scripts/Ubuntu/systemd/obsidian-sync@.service, is a template
# linked by link.sh: one instance per vault, named by its escaped path.
#
# Login and vault setup prompt for passwords, so they are printed as next steps
# rather than run. Every vault `ob` already has configured gets its sync unit
# enabled, so re-running this script after `ob sync-setup` finishes the job.

set -euo pipefail

NODE=/usr/bin/node
NPM=/usr/bin/npm
PREFIX="$HOME/.local"
PKG=obsidian-headless
PKG_DIR="$PREFIX/lib/node_modules/$PKG"
UNIT=obsidian-sync@.service
UNIT_LINK="$HOME/.config/systemd/user/$UNIT"

SKIPPED=()

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v systemctl >/dev/null 2>&1 || die "the sync daemon needs systemd, and systemctl is not on \$PATH"

require_system_node() {
  [[ -x "$NODE" && -x "$NPM" ]] \
    || die "no system node at $NODE; run scripts/Ubuntu/install_nodejs.sh first"
  local major
  major="$("$NODE" -p 'process.versions.node.split(".")[0]')"
  (( major >= 22 )) || die "$PKG needs node 22+, and $NODE is $("$NODE" --version)"
}

installed_version() {
  [[ -f "$PKG_DIR/package.json" ]] || return 0
  "$NODE" -p "require('$PKG_DIR/package.json').version"
}

install_ob() {
  local have want
  have="$(installed_version)"
  want="$("$NPM" view "$PKG" version 2>/dev/null)" || true
  if [[ -n "$have" && ( -z "$want" || "$have" == "$want" ) ]]; then
    say "$PKG already installed ($have)"
    return 0
  fi
  say "Installing $PKG ${want:-latest} into $PREFIX (system node $("$NODE" --version))"
  # /usr/bin first on PATH so better-sqlite3's install script builds or fetches
  # its binary for the system node, not for whatever nvm has active. That script
  # is the whole native module, so allow it by name: npm 11 only warns about
  # unlisted install scripts, and strict-allow-scripts would skip it silently.
  PATH="/usr/bin:$PATH" "$NPM" install -g --prefix "$PREFIX" --allow-scripts=better-sqlite3 "$PKG" \
    || { warn "$PKG install failed"; SKIPPED+=("$PKG"); return 1; }
}

# A missing or mismatched native module only shows up when sync opens its
# database, so open one now rather than fail inside a restarting unit. A bare
# require() is not enough: better-sqlite3 loads its binary on first open.
check_native() {
  "$NODE" -e "const D = require(require.resolve('better-sqlite3', { paths: ['$PKG_DIR'] })); new D(':memory:').close()" 2>/dev/null \
    || { warn "better-sqlite3 does not load under $NODE; the sync unit will fail"; SKIPPED+=("better-sqlite3"); }
}

reload_units() {
  if [[ ! -e "$UNIT_LINK" ]]; then
    warn "$UNIT is not linked yet; run scripts/Ubuntu/link.sh"
    SKIPPED+=("$UNIT (not linked)")
    return 0
  fi
  systemctl --user daemon-reload
}

# One obsidian-sync@ instance per vault that `ob sync-setup` has configured here.
# A vault that is not set up would only fail (exit 3), so it is never enabled.
enable_vault_units() {
  [[ -e "$UNIT_LINK" && -n "$(installed_version)" ]] || return 0
  command -v jq >/dev/null 2>&1 || { warn "jq is not installed; not enabling vault sync units"; SKIPPED+=("vault units (no jq)"); return 0; }
  local paths p u
  paths="$("$NODE" "$PKG_DIR/cli.js" sync-list-local --json 2>/dev/null | jq -r '.vaults[]?.path')" || true
  if [[ -z "$paths" ]]; then
    say "no vaults set up with ob yet; nothing to enable"
    return 0
  fi
  while IFS= read -r p; do
    u="obsidian-sync@$(systemd-escape --path "$p").service"
    if [[ "$(systemctl --user is-enabled "$u" 2>/dev/null | head -1)" == enabled ]]; then
      say "$u already enabled"
    else
      say "Enabling $u"
      systemctl --user enable --now "$u" || { warn "could not enable $u"; SKIPPED+=("$u"); }
    fi
  done <<<"$paths"
}

linger_on() {
  [[ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" == yes ]]
}

# Without linger, systemd stops the user manager — and the sync with it — when
# the last SSH session closes.
enable_linger() {
  linger_on && { say "linger already enabled for $USER"; return 0; }
  if sudo -n true 2>/dev/null; then
    say "Enabling linger for $USER"
    sudo loginctl enable-linger "$USER" || { warn "could not enable linger"; SKIPPED+=("linger"); }
  else
    SKIPPED+=("linger (no sudo)")
  fi
}

print_summary() {
  local v
  echo
  say "Verifying"
  v="$(installed_version)"
  if [[ -n "$v" ]]; then printf '  \033[32mok\033[0m      %s %s\n' "$PKG" "$v"
  else printf '  \033[31mmissing\033[0m %s\n' "$PKG"; fi
  if [[ -e "$UNIT_LINK" ]]; then printf '  \033[32mok\033[0m      %s\n' "$UNIT_LINK"
  else printf '  \033[31mmissing\033[0m %s\n' "$UNIT_LINK"; fi
  if linger_on; then printf '  \033[32mok\033[0m      linger (%s)\n' "$USER"
  else printf '  \033[31mmissing\033[0m linger (%s)\n' "$USER"; fi
  systemctl --user list-units 'obsidian-sync@*' --all --no-legend 2>/dev/null \
    | awk '{ printf "  unit    %s (%s)\n", $1, $4 }'
  (( ${#SKIPPED[@]} )) && { echo; warn "skipped: ${SKIPPED[*]}"; }
  echo
  linger_on || { say "Next: keep the sync running after logout"; echo "    sudo loginctl enable-linger $USER"; }
  say "Next: log in and set up a vault, then re-run this script to enable its sync unit"
  cat <<'EOF'
    ob login
    ob sync-list-remote
    ob sync-setup --vault "My Vault" --path ~/vaults/my-vault
    ~/.dotfiles/scripts/Ubuntu/install_obsidian_headless.sh
    journalctl --user -u 'obsidian-sync@*' -f
EOF
}

main() {
  require_system_node
  install_ob && check_native
  reload_units
  enable_vault_units
  enable_linger
  print_summary
}

main "$@"
