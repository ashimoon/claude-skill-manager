#!/bin/bash
# Usage: skill-accept <skill-name>
# Commits staged changes after an update

SKILLS_DIR="$HOME/.claude/skills"
SKILL_NAME="$1"

if [[ -z "$SKILL_NAME" ]]; then
  echo "Usage: skill-accept <skill-name>"
  exit 1
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

if [[ ! -d "$SKILL_DIR/.git" ]]; then
  echo "Error: Skill '$SKILL_NAME' is not git-tracked"
  exit 1
fi

cd "$SKILL_DIR"

if git diff --cached --quiet; then
  echo "No staged changes to accept."
  exit 0
fi

echo "Accepting changes for $SKILL_NAME..."
git commit -m "Update from upstream - $(date +%Y-%m-%d)"
echo "Done! Changes committed."
