#!/bin/bash
# Usage: skill-reject <skill-name>
# Discards staged changes after an update

SKILLS_DIR="$HOME/.claude/skills"
SKILL_NAME="$1"

if [[ -z "$SKILL_NAME" ]]; then
  echo "Usage: skill-reject <skill-name>"
  exit 1
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

if [[ ! -d "$SKILL_DIR/.git" ]]; then
  echo "Error: Skill '$SKILL_NAME' is not git-tracked"
  exit 1
fi

cd "$SKILL_DIR"

if git diff --cached --quiet; then
  echo "No staged changes to reject."
  exit 0
fi

echo "Rejecting changes for $SKILL_NAME..."
git reset -q HEAD
git checkout .
echo "Done! Changes discarded."
