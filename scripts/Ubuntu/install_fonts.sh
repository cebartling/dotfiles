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

set -euo pipefail

FONT_NAME="JetBrainsMono"
FONT_FAMILY="JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"

say()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }

if ! command -v fc-cache >/dev/null 2>&1; then
  warn "fontconfig not installed (apt-get install -y fontconfig); skipping fonts"
  exit 0
fi

if fc-list : family | grep -qi "$FONT_FAMILY"; then
  say "$FONT_FAMILY already installed"
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

if fc-list : family | grep -qi "$FONT_FAMILY"; then
  say "$FONT_FAMILY installed"
else
  warn "font extracted but fontconfig does not report $FONT_FAMILY"
  exit 1
fi

cat <<'EOF'

To use it in Ptyxis (the GNOME terminal on Ubuntu 24.04+), run this from a
terminal inside your desktop session:

  gsettings set org.gnome.Ptyxis use-system-font false
  gsettings set org.gnome.Ptyxis font-name 'JetBrainsMono Nerd Font 12'

EOF
