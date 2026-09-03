#!/usr/bin/env bash
# install_tailscale.sh — Tailscale on Ubuntu.
#
# The Linux counterpart to Brewfile.tailscale + scripts/macOS/install_tailscale_app.zsh.
# Opt-in and NOT wired into bootstrap.sh, exactly like the macOS version — joining
# a tailnet is a per-machine decision, and it needs sudo.
#
#   ~/.dotfiles/scripts/Ubuntu/install_tailscale.sh
#
# This is the one place in this repo that adds a third-party apt repository, and
# the exception is deliberate. Everything in install_k8s_tools.sh is a static Go
# binary that drops into ~/.local/bin with no root; Tailscale is not that. The
# `tailscale` CLI is only half of it — `tailscaled` is a privileged daemon that
# opens a TUN device and needs a systemd unit, so root is unavoidable. Once root
# is in play the vendor package beats a hand-rolled unit: pkgs.tailscale.com is
# signed, and it keeps a network-exposed daemon on the unattended-upgrade path.
# Tailscale's own docs treat the static tarball as the fallback for distros they
# do not package, not as the preferred install.
#
# Ubuntu itself ships a `tailscale` in universe, but it lags upstream by a full
# release cycle, which is the wrong trade for a daemon that speaks to the public
# internet.
#
# The script stops after enabling tailscaled. `tailscale up` needs an interactive
# browser login, so it is printed as a next step rather than run unattended.

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

KEYRING="/usr/share/keyrings/tailscale-archive-keyring.gpg"
SOURCES="/etc/apt/sources.list.d/tailscale.list"
BASE="https://pkgs.tailscale.com/stable/ubuntu"
# Suite to fall back on when Tailscale has not packaged this Ubuntu release yet.
FALLBACK_CODENAME="plucky"

SKIPPED=()

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$(uname -m)" == "x86_64" ]] || die "this installer assumes x86_64; got $(uname -m)"
command -v systemctl >/dev/null 2>&1 || die "tailscaled needs systemd, and systemctl is not on \$PATH"

# Check for usable sudo up front — every step below needs root, and a password
# prompt that nobody is there to answer just hangs.
require_sudo() {
  sudo -n true 2>/dev/null && return 0
  warn "tailscale needs sudo (apt repository, package install, systemd unit), and sudo is not available non-interactively here."
  warn "Run this script from a real terminal to include it."
  SKIPPED+=("tailscale (no sudo)")
  return 1
}

# Tailscale publishes a suite per Ubuntu codename. Verify this box's codename is
# one of them before writing a sources list that apt would then fail on.
resolve_codename() {
  local codename
  codename="$(lsb_release -cs 2>/dev/null || true)"
  [[ -n "$codename" ]] || codename="$FALLBACK_CODENAME"
  if ! curl -fsI "$BASE/dists/$codename/Release" >/dev/null 2>&1; then
    warn "Tailscale has no apt suite for '$codename' yet; falling back to '$FALLBACK_CODENAME'."
    codename="$FALLBACK_CODENAME"
  fi
  printf '%s\n' "$codename"
}

add_repo() {
  local codename tmp
  codename="$(resolve_codename)"

  if [[ -s "$KEYRING" && -s "$SOURCES" ]] && grep -q "pkgs.tailscale.com" "$SOURCES"; then
    say "Tailscale apt repository already configured ($(awk '/^deb /{print $(NF-1); exit}' "$SOURCES"))"
    return 0
  fi

  say "Adding the Tailscale apt repository for $codename"
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/keyring.gpg" "$BASE/$codename.noarmor.gpg" \
     && curl -fsSL -o "$tmp/tailscale.list" "$BASE/$codename.tailscale-keyring.list"; then
    # The upstream .list already carries signed-by=$KEYRING.
    grep -q "signed-by=$KEYRING" "$tmp/tailscale.list" \
      || die "upstream sources list no longer points at $KEYRING; check it before installing"
    sudo install -m 0644 "$tmp/keyring.gpg" "$KEYRING"
    sudo install -m 0644 "$tmp/tailscale.list" "$SOURCES"
    sudo apt-get update -qq
  else
    warn "could not download the Tailscale repository key or sources list"
    SKIPPED+=("tailscale (repo download failed)")
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"
}

install_tailscale() {
  if command -v tailscale >/dev/null 2>&1 || dpkg -s tailscale >/dev/null 2>&1; then
    say "tailscale already installed ($(tailscale version 2>/dev/null | head -1))"
    return 0
  fi
  say "Installing tailscale (needs sudo)"
  sudo apt-get install -y tailscale || { warn "tailscale install failed"; SKIPPED+=(tailscale); return 1; }
}

enable_daemon() {
  command -v tailscaled >/dev/null 2>&1 || return 0
  if [[ "$(systemctl is-enabled tailscaled 2>/dev/null)" == "enabled" ]] \
     && systemctl is-active --quiet tailscaled; then
    say "tailscaled already enabled and running"
    return 0
  fi
  say "Enabling and starting tailscaled"
  sudo systemctl enable --now tailscaled || { warn "could not enable tailscaled"; SKIPPED+=("tailscaled (systemd)"); return 0; }
  systemctl is-active --quiet tailscaled \
    || warn "tailscaled is installed but not running — 'systemctl status tailscaled' will say why. 'tailscale up' will not work until it does."
}

# Every step below needs root, so a re-run on a finished box should short-circuit
# before the sudo gate rather than warn about a password it does not need.
nothing_to_do() {
  command -v tailscale >/dev/null 2>&1 \
    && [[ -s "$KEYRING" && -s "$SOURCES" ]] \
    && [[ "$(systemctl is-enabled tailscaled 2>/dev/null | head -1)" == "enabled" ]] \
    && systemctl is-active --quiet tailscaled
}

print_summary() {
  echo
  say "Verifying"
  for t in tailscale tailscaled; do
    if command -v "$t" >/dev/null 2>&1; then printf '  \033[32mok\033[0m      %s\n' "$t"
    else printf '  \033[31mmissing\033[0m %s\n' "$t"; fi
  done
  # systemctl prints its answer and still exits non-zero for a missing unit, so
  # take the first line and ignore the status.
  printf '  unit    tailscaled (%s, %s)\n' \
    "$(systemctl is-enabled tailscaled 2>/dev/null | head -1)" \
    "$(systemctl is-active tailscaled 2>/dev/null | head -1)"
  (( ${#SKIPPED[@]} )) && { echo; warn "skipped: ${SKIPPED[*]}"; }
  echo
  if command -v tailscale >/dev/null 2>&1 && tailscale status >/dev/null 2>&1; then
    say "Already logged in: $(tailscale ip -4 2>/dev/null | head -1)"
  else
    say "Next: join the tailnet (opens a browser login)"
    echo "    sudo tailscale up --ssh --accept-routes"
  fi
  echo
  warn "Docker containers reach the tailnet outside DOCKER-USER containment: ~/bin/docker-user-firewall.sh hardcodes WAN_IFS and does not know about tailscale0 (beads dotfiles-0qc)."
}

main() {
  if nothing_to_do; then
    say "Tailscale is already installed and tailscaled is running"
    print_summary
    return 0
  fi
  require_sudo || { print_summary; return 0; }
  add_repo     || { print_summary; return 0; }
  install_tailscale || { print_summary; return 0; }
  enable_daemon
  print_summary
}

main "$@"
