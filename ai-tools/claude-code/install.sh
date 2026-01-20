#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SOURCE_DIR=~/.dotfiles/ai-tools/claude-code
DEST_DIR=~/.claude

echo -e "${BLUE}Installing Claude Code configuration...${NC}"

if [[ ! -d "$DEST_DIR" ]]; then
    echo -e "${GREEN}Creating $DEST_DIR directory${NC}"
    mkdir "$DEST_DIR"
fi

if [[ ! -d "$DEST_DIR/commands" ]]; then
    echo -e "${GREEN}Creating $DEST_DIR/commands directory${NC}"
    mkdir "$DEST_DIR/commands"
fi

echo -e "${GREEN}Copying CLAUDE.md${NC}"
cp "$SOURCE_DIR/CLAUDE.md" "$DEST_DIR/CLAUDE.md"

if ! diff -q "$SOURCE_DIR/CLAUDE.md" "$DEST_DIR/CLAUDE.md" > /dev/null 2>&1; then
    echo -e "${RED}Error: CLAUDE.md verification failed${NC}"
    exit 1
fi

echo -e "${GREEN}Copying command files${NC}"
cp "$SOURCE_DIR/commands/"*.md "$DEST_DIR/commands/"

for src_file in "$SOURCE_DIR/commands/"*.md; do
    filename=$(basename "$src_file")
    dest_file="$DEST_DIR/commands/$filename"
    if ! diff -q "$src_file" "$dest_file" > /dev/null 2>&1; then
        echo -e "${RED}Error: $filename verification failed${NC}"
        exit 1
    fi
done

file_count=$((1 + $(ls -1 "$SOURCE_DIR/commands/"*.md 2>/dev/null | wc -l)))
echo -e "${BLUE}Done! All files verified. ($file_count files copied)${NC}"
