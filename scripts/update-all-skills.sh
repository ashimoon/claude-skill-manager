#!/bin/bash
# Usage: update-all-skills
# Updates all managed skills and reports status for each

SKILLS_DIR="$HOME/.claude/skills"
SCRIPT_DIR="$(dirname "$0")"

# Arrays to track results
declare -a UPDATED_SKILLS=()
declare -a NO_CHANGES_SKILLS=()
declare -a UNMANAGED_SKILLS=()
declare -a DIRTY_SKILLS=()

echo "Checking all skills for updates..."
echo ""

for dir in "$SKILLS_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  name=$(basename "$dir")

  METADATA_FILE="$dir/.skill-manager.json"

  if [[ -f "$METADATA_FILE" ]]; then
    # Managed skill - check for uncommitted changes first
    if [[ -d "$dir/.git" ]]; then
      cd "$dir"
      if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        DIRTY_SKILLS+=("$name")
        echo "Skipping: $name (has uncommitted local changes)"
        cd - > /dev/null
        echo ""
        continue
      fi
      cd - > /dev/null
    fi

    # Attempt update
    SOURCE_URL=$(jq -r '.source_url' "$METADATA_FILE" 2>/dev/null)
    echo "Updating: $name"
    echo "  Source: $SOURCE_URL"

    # Run install script and capture output
    output=$("$SCRIPT_DIR/install-skill.sh" "$SOURCE_URL" --target "$name" 2>&1)

    if echo "$output" | grep -q "No changes from upstream"; then
      NO_CHANGES_SKILLS+=("$name")
      echo "  Status: Up to date"
    elif echo "$output" | grep -q "Changes detected"; then
      UPDATED_SKILLS+=("$name")
      echo "  Status: Changes available (staged for review)"
    else
      # Check if there was an error
      if echo "$output" | grep -qi "error\|failed"; then
        echo "  Status: Error - $output"
      else
        NO_CHANGES_SKILLS+=("$name")
        echo "  Status: Up to date"
      fi
    fi
    echo ""
  else
    # Unmanaged skill
    UNMANAGED_SKILLS+=("$name")
  fi
done

# Print summary
echo "========================================"
echo "                SUMMARY                 "
echo "========================================"
echo ""

if [[ ${#UPDATED_SKILLS[@]} -gt 0 ]]; then
  echo "UPDATES AVAILABLE (${#UPDATED_SKILLS[@]}):"
  for skill in "${UPDATED_SKILLS[@]}"; do
    echo "  • $skill [PENDING CHANGES]"
  done
  echo ""
  echo "  Run 'skill-accept.sh <name>' to accept changes"
  echo "  Run 'skill-reject.sh <name>' to reject changes"
  echo ""
fi

if [[ ${#NO_CHANGES_SKILLS[@]} -gt 0 ]]; then
  echo "UP TO DATE (${#NO_CHANGES_SKILLS[@]}):"
  for skill in "${NO_CHANGES_SKILLS[@]}"; do
    echo "  • $skill"
  done
  echo ""
fi

if [[ ${#DIRTY_SKILLS[@]} -gt 0 ]]; then
  echo "SKIPPED - LOCAL CHANGES (${#DIRTY_SKILLS[@]}):"
  for skill in "${DIRTY_SKILLS[@]}"; do
    echo "  • $skill"
  done
  echo ""
  echo "  These skills have uncommitted local changes."
  echo "  Commit or discard changes, then run update again."
  echo ""
fi

if [[ ${#UNMANAGED_SKILLS[@]} -gt 0 ]]; then
  echo "NOT MANAGED (${#UNMANAGED_SKILLS[@]}):"
  for skill in "${UNMANAGED_SKILLS[@]}"; do
    echo "  • $skill"
  done
  echo ""
  echo "  These skills were not installed via skill-manager."
  echo "  Use 'install-skill.sh <github-url> --force' to manage them."
  echo ""
fi

# Exit with appropriate code
if [[ ${#UPDATED_SKILLS[@]} -gt 0 ]]; then
  exit 2  # Updates available
else
  exit 0  # All up to date
fi
