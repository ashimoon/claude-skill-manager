#!/bin/bash
# Usage: rename-skill <current-name> <new-name>

SKILLS_DIR="$HOME/.claude/skills"
CURRENT_NAME="$1"
NEW_NAME="$2"

if [[ -z "$CURRENT_NAME" || -z "$NEW_NAME" ]]; then
  echo "Usage: rename-skill <current-name> <new-name>"
  exit 1
fi

CURRENT_DIR="$SKILLS_DIR/$CURRENT_NAME"
NEW_DIR="$SKILLS_DIR/$NEW_NAME"

if [[ ! -d "$CURRENT_DIR" ]]; then
  echo "Error: Skill '$CURRENT_NAME' not found"
  exit 1
fi

if [[ -d "$NEW_DIR" ]]; then
  echo "Error: Skill '$NEW_NAME' already exists"
  exit 1
fi

if [[ "$CURRENT_NAME" == "skill-manager" ]]; then
  echo "Error: Cannot rename skill-manager"
  exit 1
fi

mv "$CURRENT_DIR" "$NEW_DIR"
echo "Renamed: $CURRENT_NAME -> $NEW_NAME"
