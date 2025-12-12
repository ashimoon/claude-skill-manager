#!/bin/bash
# Usage: list-skills
# Lists all installed skills and their sources

SKILLS_DIR="$HOME/.claude/skills"

echo "Installed Skills"
echo ""

for dir in "$SKILLS_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  name=$(basename "$dir")

  if [[ -f "$dir/.skill-manager.json" ]]; then
    source=$(jq -r '.source_url' "$dir/.skill-manager.json" 2>/dev/null)

    # Check for pending changes
    if [[ -d "$dir/.git" ]]; then
      cd "$dir"
      if ! git diff --cached --quiet 2>/dev/null; then
        status=" [PENDING CHANGES]"
      else
        status=""
      fi
      cd - > /dev/null
    else
      status=""
    fi

    desc=$(head -5 "$dir/SKILL.md" 2>/dev/null | grep "^description:" | sed 's/description: //')
    echo "• $name$status"
    echo "  └─ $source"
    [[ -n "$desc" ]] && echo "     $desc"
  else
    desc=$(head -5 "$dir/SKILL.md" 2>/dev/null | grep "^description:" | sed 's/description: //')
    echo "• $name (not managed)"
    [[ -n "$desc" ]] && echo "     $desc"
  fi
  echo ""
done
