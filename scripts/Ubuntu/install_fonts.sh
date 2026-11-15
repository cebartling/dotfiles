#!/usr/bin/env bash
# install_fonts.sh — install the Nerd Font the shell config depends on.
#
# aliases/core.sh renders `eza --icons` and configurations/starship.toml
# uses Nerd Font glyphs, so without a patched font both show tofu boxes.
# This installs JetBrainsMono Nerd Font, matching the
# font-jetbrains-mono-nerd-font cask in the macOS Brewfile.
#
# Idempotent: skips the download if the family is already registered.
# Installs per-user (no sudo) into ~/.local/share/fonts.

# --- install-all metadata ---
# Read by install_all.sh. Keep this in sync with any new hard
# precondition added below, or install_all will not know about it.
# summary: JetBrainsMono Nerd Font, per-user, no root
# group: core
# wants: install_tools.sh
# needs-cmd: fc-cache
# sudo: none
# --- end metadata ---

set -euo pipefail

FONT_NAME="JetBrainsMono"
FONT_FAMILY="JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }

# Point GNOME's system monospace font at the Nerd Font, so editors, code views
# and any terminal left on "use system font" get the glyphs too. Only inside a
# desktop session: without a session bus gsettings writes to a throwaway
# in-memory backend and warns on stderr. Size 11 matches the Ubuntu default.
SYSTEM_MONO_FONT="$FONT_FAMILY 11"
set_system_mono_font() {
  command -v gsettings >/dev/null 2>&1 || return 0
  [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] || return 0
  gsettings list-keys org.gnome.desktop.interface 2>/dev/null \
    | grep -qx monospace-font-name || return 0
  [[ "$(gsettings get org.gnome.desktop.interface monospace-font-name)" == "'$SYSTEM_MONO_FONT'" ]] && return 0
  say "Setting the GNOME system monospace font to $SYSTEM_MONO_FONT"
  gsettings set org.gnome.desktop.interface monospace-font-name "$SYSTEM_MONO_FONT" \
    || warn "could not set the system monospace font; continuing"
}

if ! command -v fc-cache >/dev/null 2>&1; then
  warn "fontconfig not installed (apt-get install -y fontconfig); skipping fonts"
  exit 0
fi

if fc-list : family | grep -i "$FONT_FAMILY" >/dev/null; then
  say "$FONT_FAMILY already installed"
  set_system_mono_font
  exit 0
fi

say "Resolving latest ryanoasis/nerd-fonts release"
URL="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
      | grep -o "https://[^\"]*/${FONT_NAME}\.tar\.xz" | head -1)" || true

if [[ -z "${URL:-}" ]]; then
  warn "could not resolve a download URL for ${FONT_NAME}.tar.xz"
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

say "Downloading $FONT_NAME Nerd Font"
curl -fsSL -o "$TMP/$FONT_NAME.tar.xz" "$URL"

say "Extracting to $FONT_DIR"
mkdir -p "$FONT_DIR"
tar -xJf "$TMP/$FONT_NAME.tar.xz" -C "$FONT_DIR"

# The archive ships license and readme files alongside the fonts.
rm -f "$FONT_DIR"/*.md "$FONT_DIR"/LICENSE* 2>/dev/null || true

say "Rebuilding the font cache"
fc-cache -f "$FONT_DIR" >/dev/null

if fc-list : family | grep -i "$FONT_FAMILY" >/dev/null; then
  say "$FONT_FAMILY installed"
else
  warn "font extracted but fontconfig does not report $FONT_FAMILY"
  exit 1
fi

set_system_mono_font

cat <<'EOF'

To use it in Ptyxis (the GNOME terminal on Ubuntu 24.04+), run this from a
terminal inside your desktop session:

  gsettings set org.gnome.Ptyxis use-system-font false
  gsettings set org.gnome.Ptyxis font-name 'JetBrainsMono Nerd Font 12'

EOF
