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
    [[ -d "$dir" ]] || continue
    name=$(basename "$dir")

    # Check for origin remote first (cloned repos)
    if [[ -d "$dir/.git" ]] && git -C "$dir" remote get-url origin &>/dev/null; then
      origin=$(git -C "$dir" remote get-url origin | sed 's|https://github.com/||' | sed 's|\.git$||')
      echo "  $name -> $origin (cloned)"
    elif [[ -f "$dir/.skill-manager.json" ]]; then
      source=$(jq -r '.source_url' "$dir/.skill-manager.json" 2>/dev/null | sed 's|https://github.com/||')
      echo "  $name -> $source"
    else
      echo "  $name (not managed)"
    fi
  done
  exit 1
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"
METADATA_FILE="$SKILL_DIR/.skill-manager.json"

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "Error: Skill '$SKILL_NAME' not found in $SKILLS_DIR"
  exit 1
fi

# Check if the skill has an origin remote (cloned repo)
if [[ -d "$SKILL_DIR/.git" ]] && git -C "$SKILL_DIR" remote get-url origin &>/dev/null; then
  ORIGIN_URL=$(git -C "$SKILL_DIR" remote get-url origin)
  BRANCH=$(git -C "$SKILL_DIR" rev-parse --abbrev-ref HEAD)

  echo "Updating $SKILL_NAME from origin:"
  echo "  $ORIGIN_URL (branch: $BRANCH)"
  echo ""

  cd "$SKILL_DIR"

  # Check for uncommitted changes
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    echo "WARNING: You have uncommitted local changes!"
    git status --short
    echo ""
    read -p "Stash changes and continue? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      git stash
      STASHED=true
    else
      echo "Aborted."
      exit 1
    fi
  fi

  # Fetch and check for updates
  git fetch origin "$BRANCH"

  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse "origin/$BRANCH")

  if [[ "$LOCAL" == "$REMOTE" ]]; then
    echo "No changes from upstream."
    if [[ "${STASHED:-false}" == true ]]; then
      git stash pop
    fi
    exit 0
  fi

  echo "=== Changes detected ==="
  git log --oneline HEAD.."origin/$BRANCH"
  echo ""
  git diff --stat HEAD.."origin/$BRANCH"
  echo ""

  read -p "Pull these changes? [Y/n] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    git pull origin "$BRANCH"
    echo ""
    echo "Updated successfully!"
  else
    echo "Aborted."
  fi

  if [[ "${STASHED:-false}" == true ]]; then
    echo ""
    echo "Restoring stashed changes..."
    git stash pop
  fi

  exit 0
fi

# Fall back to metadata-based update for API-installed skills
if [[ ! -f "$METADATA_FILE" ]]; then
  echo "Error: Skill '$SKILL_NAME' has no origin remote and no .skill-manager.json"
  echo "Cannot determine update source."
  exit 1
fi

SOURCE_URL=$(jq -r '.source_url' "$METADATA_FILE")
echo "Updating $SKILL_NAME from:"
echo "  $SOURCE_URL"
echo ""

# Re-run install script with --target to preserve skill name
SCRIPT_DIR="$(dirname "$0")"
"$SCRIPT_DIR/install-skill.sh" "$SOURCE_URL" --target "$SKILL_NAME"
