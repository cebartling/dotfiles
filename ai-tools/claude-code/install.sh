#!/bin/bash
# Sync Claude Code config from this dotfiles repo into ~/.claude via
# symlinks. Edits in either location are reflected in both places, so
# the dotfiles repo stays the source of truth without a re-install step.
# Pre-existing real files/dirs at the destination are backed up to
# <path>.backup.<timestamp> before being replaced.
#
# skills/ uses the same <skill-name>/SKILL.md layout as Claude Code
# plugins, so a future migration to a personal plugin would only need
# a plugin manifest, not a file reshuffle.

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
SOURCE_DIR="$DOTFILES/ai-tools/claude-code"
DEST_DIR="$HOME/.claude"
TS="$(date +%Y%m%d-%H%M%S)"

link() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo -e "${RED}missing source: $src${NC}"
    return 1
  fi

  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo -e "${GREEN}ok    ${NC} $dst -> $src"
    return 0
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    local backup="${dst}.backup.${TS}"
    echo -e "${YELLOW}backup${NC} $dst -> $backup"
    mv "$dst" "$backup"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo -e "${CYAN}link  ${NC} $dst -> $src"
}

echo -e "${BLUE}Linking Claude Code config from $SOURCE_DIR...${NC}"
echo

mkdir -p "$DEST_DIR/commands" "$DEST_DIR/hooks" "$DEST_DIR/skills"

link "$SOURCE_DIR/CLAUDE.md" "$DEST_DIR/CLAUDE.md"
link "$SOURCE_DIR/settings.json" "$DEST_DIR/settings.json"

for src in "$SOURCE_DIR/commands/"*; do
  [[ -e "$src" ]] || continue
  link "$src" "$DEST_DIR/commands/$(basename "$src")"
done

for src in "$SOURCE_DIR/hooks/"*; do
  [[ -e "$src" ]] || continue
  link "$src" "$DEST_DIR/hooks/$(basename "$src")"
done

for src in "$SOURCE_DIR/skills/"*; do
  [[ -d "$src" ]] || continue
  link "$src" "$DEST_DIR/skills/$(basename "$src")"
done

echo
echo -e "${BLUE}Done.${NC}"
