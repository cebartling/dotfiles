#!/usr/bin/env bash
# link.sh — symlink dotfiles into place on Linux. Idempotent and safe:
# any existing non-symlink target is backed up to <file>.backup.<timestamp>
# before being replaced. Re-running on a linked system is a no-op.
#
# The Linux counterpart to scripts/macOS/link.zsh. The cmux links are
# omitted (macOS app, one of them targets ~/Library/Application Support),
# and the ghostty config is linked only if ghostty is actually installed.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
TS="$(date +%Y%m%d-%H%M%S)"

C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'
C_CYN=$'\033[36m'; C_RST=$'\033[0m'

# link <source> <target>
#   source: file inside $DOTFILES
#   target: absolute path under $HOME
link() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "${C_RED}missing source: $src${C_RST}"
    return 1
  fi

  # Already correctly linked? Nothing to do.
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "${C_GRN}ok${C_RST}     $dst -> $src"
    return 0
  fi

  # Existing file/dir/symlink that points elsewhere — back it up.
  if [[ -e "$dst" || -L "$dst" ]]; then
    local backup="${dst}.backup.${TS}"
    echo "${C_YEL}backup${C_RST} $dst -> $backup"
    mv "$dst" "$backup"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "${C_CYN}link${C_RST}   $dst -> $src"
}

echo "${C_CYN}Linking dotfiles from $DOTFILES...${C_RST}"
echo

link "$DOTFILES/zshrc"                        "$HOME/.zshrc"
link "$DOTFILES/configurations/starship.toml" "$HOME/.config/starship.toml"

# The one tracked executable meant to land on $PATH. ~/.local/bin is already
# on $path via zshrc; link() creates the directory if it is missing.
link "$DOTFILES/scripts/Ubuntu/wlheadless-run" "$HOME/.local/bin/wlheadless-run"

# Host-maintenance scripts. These keep their historical home in ~/bin (also on
# $path) rather than moving to ~/.local/bin — they are run by hand, usually
# under sudo, and the paths are quoted in the provisioning journal.
for s in docker-user-firewall.sh install-docker.sh ufw-docker-test.sh; do
  link "$DOTFILES/scripts/Ubuntu/bin/$s" "$HOME/bin/$s"
done

# Files (Nautilus) right-click -> Scripts entries.
if command -v nautilus >/dev/null 2>&1; then
  link "$DOTFILES/scripts/Ubuntu/nautilus/Open with Zed" \
       "$HOME/.local/share/nautilus/scripts/Open with Zed"
else
  echo "${C_YEL}skip${C_RST}   nautilus scripts (nautilus not installed)"
fi

# Tailscale tray client: one .desktop, linked twice — autostart at login, and the
# app grid so it can be relaunched after Quit. Needs the tailscaled operator set
# to this user (install_tailscale.sh does that) to connect without sudo.
if command -v tailscale >/dev/null 2>&1; then
  link "$DOTFILES/scripts/Ubuntu/desktop/tailscale-systray.desktop" \
       "$HOME/.config/autostart/tailscale-systray.desktop"
  link "$DOTFILES/scripts/Ubuntu/desktop/tailscale-systray.desktop" \
       "$HOME/.local/share/applications/tailscale-systray.desktop"
  # HTTPS certificate renewal: the script, and a daily systemd user timer that
  # runs it. Enabling the timer is a one-time manual step (see PACKAGES.md).
  link "$DOTFILES/scripts/Ubuntu/tailscale-cert-renew" "$HOME/.local/bin/tailscale-cert-renew"
  for u in tailscale-cert-renew.service tailscale-cert-renew.timer; do
    link "$DOTFILES/scripts/Ubuntu/systemd/$u" "$HOME/.config/systemd/user/$u"
  done
else
  echo "${C_YEL}skip${C_RST}   tailscale systray and cert renewal (tailscale not installed)"
fi

# Headless Obsidian Sync: a systemd user template, one instance per vault.
# Linked whenever systemd is present — a template does nothing until an instance
# is enabled — so link.sh need not run after install_obsidian_headless.sh.
if command -v systemctl >/dev/null 2>&1; then
  link "$DOTFILES/scripts/Ubuntu/systemd/obsidian-sync@.service" \
       "$HOME/.config/systemd/user/obsidian-sync@.service"
else
  echo "${C_YEL}skip${C_RST}   obsidian-sync unit (no systemd)"
fi

if command -v ghostty >/dev/null 2>&1; then
  link "$DOTFILES/configurations/ghostty/config" "$HOME/.config/ghostty/config"
else
  echo "${C_YEL}skip${C_RST}   ghostty config (ghostty not installed)"
fi

echo
echo "${C_CYN}Done.${C_RST}"
