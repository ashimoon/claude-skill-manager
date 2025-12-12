#!/bin/bash
# Usage: update-skill <skill-name>
# Example: update-skill command-development

SKILLS_DIR="$HOME/.claude/skills"
SKILL_NAME="$1"

if [[ -z "$SKILL_NAME" ]]; then
  echo "Usage: update-skill <skill-name>"
  echo ""
  echo "Installed skills:"
  for dir in "$SKILLS_DIR"/*/; do
    if [[ -f "$dir/.skill-installer.json" ]]; then
      name=$(basename "$dir")
      source=$(jq -r '.source_url' "$dir/.skill-installer.json" 2>/dev/null | sed 's|https://github.com/||')
      echo "  $name -> $source"
    fi
  done
  exit 1
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"
METADATA_FILE="$SKILL_DIR/.skill-installer.json"

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "Error: Skill '$SKILL_NAME' not found in $SKILLS_DIR"
  exit 1
fi

if [[ ! -f "$METADATA_FILE" ]]; then
  echo "Error: Skill '$SKILL_NAME' was not installed by skill-installer (no .skill-installer.json)"
  exit 1
fi

SOURCE_URL=$(jq -r '.source_url' "$METADATA_FILE")
echo "Updating $SKILL_NAME from:"
echo "  $SOURCE_URL"
echo ""

# Re-run install script with --target to preserve skill name
SCRIPT_DIR="$(dirname "$0")"
"$SCRIPT_DIR/install-skill.sh" "$SOURCE_URL" --target "$SKILL_NAME"
