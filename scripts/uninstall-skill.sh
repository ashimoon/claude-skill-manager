#!/bin/bash
# Usage: uninstall-skill <skill-name>

SKILLS_DIR="$HOME/.claude/skills"
SKILL_NAME="$1"

if [[ -z "$SKILL_NAME" ]]; then
  echo "Usage: uninstall-skill <skill-name>"
  exit 1
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "Error: Skill '$SKILL_NAME' not found"
  exit 1
fi

rm -rf "$SKILL_DIR"
echo "Uninstalled: $SKILL_NAME"
