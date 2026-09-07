#!/usr/bin/env bash
# install_chrome.sh — Google Chrome on Ubuntu.
#
# Opt-in and NOT wired into bootstrap.sh, like install_tailscale.sh and
# install_k8s_tools.sh — a GUI browser is a desktop decision, not something a
# headless box wants pulled in, and it needs sudo.
#
#   ~/.dotfiles/scripts/Ubuntu/install_chrome.sh
#
# Ubuntu does not package Chrome, and its Chromium is a snap wrapper around a
# different browser. Google publishes one signed apt repository for every
# release — a single `stable main` suite, not per-codename — so unlike Tailscale
# there is nothing to resolve against `lsb_release -cs`, and a brand-new Ubuntu
# works on day one.
#
# We add the keyring and sources file ourselves rather than side-loading the
# standalone .deb: `apt-get install ./google-chrome-stable.deb` verifies no
# signature at all, whereas an apt source does, and it keeps a network-facing
# browser on the unattended-upgrade path.
#
# The chrome package's postinst wants to write its own sources list, keyed off
# /etc/apt/trusted.gpg.d (the deprecated global-trust location). That knob lives
# in /etc/default/google-chrome, which is a conffile the package itself ships —
# pre-creating it would make dpkg stop on a conffile conflict — so this script
# reconciles *after* the install instead: rewrite the source with signed-by and
# set repo_add_once=false so the postinst never re-adds it on upgrade.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

KEYRING="/usr/share/keyrings/google-chrome.gpg"
SOURCES="/etc/apt/sources.list.d/google-chrome.list"
DEFAULTS="/etc/default/google-chrome"
KEY_URL="https://dl.google.com/linux/linux_signing_key.pub"
REPO_URL="https://dl.google.com/linux/chrome/deb/"

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Google ships Chrome for Linux as amd64 only — there is no arm64 .deb. Say so
# rather than letting apt fail with an unhelpful "unable to locate package".
[[ "$(uname -m)" == "x86_64" ]] \
  || die "Google publishes no arm64 Chrome for Linux; got $(uname -m). Use 'sudo snap install chromium' instead."

# Every step below needs root, and a password prompt nobody is there to answer
# just hangs.
require_sudo() {
  sudo -n true 2>/dev/null && return 0
  warn "chrome needs sudo (apt repository, package install), and sudo is not available non-interactively here."
  die "Run this script from a real terminal."
}

# Write the signed-by source. Idempotent: called again after the install to undo
# whatever the postinst decided to put at $SOURCES.
write_source() {
  printf 'deb [arch=amd64 signed-by=%s] %s stable main\n' "$KEYRING" "$REPO_URL" \
    | sudo tee "$SOURCES" >/dev/null
}

add_repo() {
  if [[ -s "$KEYRING" && -s "$SOURCES" ]] && grep -q "signed-by=$KEYRING" "$SOURCES"; then
    say "Google Chrome apt repository already configured"
    return 0
  fi

  say "Adding the Google Chrome apt repository"
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/key.pub" "$KEY_URL" \
    || die "could not download the Google signing key from $KEY_URL"
  gpg --dearmor -o "$tmp/keyring.gpg" "$tmp/key.pub" \
    || die "the downloaded key is not an armored PGP key; refusing to install it"
  sudo install -m 0644 "$tmp/keyring.gpg" "$KEYRING"
  rm -rf "$tmp"

  write_source
  sudo apt-get update -qq
}

# Runs after the install, when $DEFAULTS exists as a package conffile.
pin_repo_ownership() {
  if grep -q "signed-by=$KEYRING" "$SOURCES" 2>/dev/null; then
    :
  else
    say "Restoring the signed-by apt source the postinst replaced"
    write_source
  fi

  if [[ -f "$DEFAULTS" ]] && grep -q '^repo_add_once=' "$DEFAULTS"; then
    sudo sed -i 's/^repo_add_once=.*/repo_add_once="false"/' "$DEFAULTS"
  else
    printf 'repo_add_once="false"\n' | sudo tee -a "$DEFAULTS" >/dev/null
  fi
}

install_chrome() {
  if command -v google-chrome-stable >/dev/null 2>&1; then
    say "Google Chrome already installed ($(google-chrome-stable --version))"
    return 0
  fi
  say "Installing google-chrome-stable"
  sudo apt-get install -y google-chrome-stable
}

require_sudo
add_repo
install_chrome
pin_repo_ownership

echo
say "Installed: $(google-chrome-stable --version)"
say "Updates arrive through apt with the rest of the system."
