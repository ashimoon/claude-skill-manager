#!/bin/bash
# Usage: install-skill <github-url> [--target <name>] [--force]
# Example: install-skill https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev/skills/command-development
# Example: install-skill https://github.com/owner/repo/tree/main/path/to/skill --target my-custom-name

set -e

SKILLS_DIR="$HOME/.claude/skills"
FORCE=false
TARGET_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET_NAME="$2"
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    *)
      URL="$1"
      shift
      ;;
  esac
done

if [[ -z "$URL" ]]; then
  echo "Usage: install-skill <github-url> [--target <name>] [--force]"
  echo ""
  echo "Options:"
  echo "  --target <name>  Install with a custom skill name"
  echo "  --force          Overwrite existing skill without prompting"
  exit 1
fi

# Parse GitHub URL - handles both formats:
#   https://github.com/owner/repo
#   https://github.com/owner/repo/tree/branch/path/to/skill
OWNER=$(echo "$URL" | sed -E 's|https://github.com/([^/]+)/.*|\1|')
REPO=$(echo "$URL" | sed -E 's|https://github.com/[^/]+/([^/]+).*|\1|' | sed 's|/.*||')

if [[ "$URL" =~ /tree/ ]]; then
  BRANCH=$(echo "$URL" | sed -E 's|https://github.com/[^/]+/[^/]+/tree/([^/]+).*|\1|')
  SKILL_PATH=$(echo "$URL" | sed -E 's|https://github.com/[^/]+/[^/]+/tree/[^/]+/(.*)|\1|')
  # If no path after branch, use empty string
  if [[ "$SKILL_PATH" == "$URL" ]]; then
    SKILL_PATH=""
  fi
else
  # Default to main branch, root path
  BRANCH="main"
  SKILL_PATH=""
fi

# Use custom target name or derive from URL
if [[ -n "$TARGET_NAME" ]]; then
  SKILL_NAME="$TARGET_NAME"
elif [[ -n "$SKILL_PATH" ]]; then
  SKILL_NAME=$(basename "$SKILL_PATH")
else
  SKILL_NAME="$REPO"
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"
METADATA_FILE="$SKILL_DIR/.skill-manager.json"

echo "Source: $OWNER/$REPO/$SKILL_PATH (branch: $BRANCH)"
echo "Target: $SKILL_NAME"

# Check for existing skill
IS_UPDATE=false
if [[ -d "$SKILL_DIR" ]]; then
  if [[ -f "$METADATA_FILE" ]]; then
    EXISTING_URL=$(jq -r '.source_url' "$METADATA_FILE" 2>/dev/null || echo "")
    if [[ "$EXISTING_URL" == "$URL" ]]; then
      echo ""
      echo "Skill already installed from same source. Checking for updates..."
      IS_UPDATE=true
    else
      echo ""
      echo "WARNING: Skill '$SKILL_NAME' already exists but from a different source!"
      echo "  Existing: $EXISTING_URL"
      echo "  New:      $URL"
      if [[ "$FORCE" != true ]]; then
        echo ""
        echo "Options:"
        echo "  1. Use --force to overwrite"
        echo "  2. Use --target <new-name> to install with different name"
        exit 1
      fi
      echo "Force flag set, overwriting..."
      IS_UPDATE=true
    fi
  else
    echo ""
    echo "WARNING: Skill '$SKILL_NAME' exists but wasn't installed by skill-installer."
    if [[ "$FORCE" != true ]]; then
      echo "Use --force to overwrite or --target <new-name> to install with different name."
      exit 1
    fi
    echo "Force flag set, overwriting..."
    IS_UPDATE=false
  fi
fi

# Check for uncommitted changes in existing skill directory
if [[ -d "$SKILL_DIR/.git" ]]; then
  cd "$SKILL_DIR"
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    echo ""
    echo "WARNING: Skill '$SKILL_NAME' has uncommitted local changes!"
    git status --short
    echo ""
    if [[ "$FORCE" != true ]]; then
      read -p "Proceed and overwrite these changes? [y/N] " -n 1 -r
      echo ""
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
      fi
    else
      echo "Force flag set, proceeding anyway..."
    fi
  fi
  cd - > /dev/null
fi

# Function to download directory contents recursively
download_dir() {
  local api_path="$1"
  local local_dir="$2"

  local response=$(curl -sL "https://api.github.com/repos/$OWNER/$REPO/contents/$api_path?ref=$BRANCH")

  # Check for API errors
  if echo "$response" | jq -e '.message' >/dev/null 2>&1; then
    echo "API Error: $(echo "$response" | jq -r '.message')"
    return 1
  fi

  echo "$response" | jq -c '.[]' 2>/dev/null | while read -r item; do
    local name=$(echo "$item" | jq -r '.name')
    local type=$(echo "$item" | jq -r '.type')
    local download_url=$(echo "$item" | jq -r '.download_url')

    # Skip our metadata file if it exists in source
    if [[ "$name" == ".skill-manager.json" ]]; then
      continue
    fi

    if [[ "$type" == "file" ]]; then
      echo "  Downloading: $name"
      curl -sL "$download_url" -o "$local_dir/$name"
    elif [[ "$type" == "dir" ]]; then
      mkdir -p "$local_dir/$name"
      download_dir "$api_path/$name" "$local_dir/$name"
    fi
  done
}

# Create skill directory
mkdir -p "$SKILL_DIR"

# Initialize git if needed
if [[ ! -d "$SKILL_DIR/.git" ]]; then
  echo ""
  echo "Initializing git repository..."
  cd "$SKILL_DIR"
  git init -q
fi

echo ""
echo "Downloading files..."
download_dir "$SKILL_PATH" "$SKILL_DIR"

# Create metadata file only on first install
if [[ ! -f "$METADATA_FILE" ]]; then
  echo ""
  echo "Writing metadata..."
  cat > "$METADATA_FILE" << EOF
{
  "source_url": "$URL",
  "owner": "$OWNER",
  "repo": "$REPO",
  "branch": "$BRANCH",
  "path": "$SKILL_PATH"
}
EOF
fi

cd "$SKILL_DIR"
git add -A

if [[ "$IS_UPDATE" == true ]]; then
  # Show changes for updates
  echo ""
  if git diff --cached --quiet; then
    echo "No changes from upstream."
    git reset -q HEAD
    exit 0
  fi
  echo "=== Changes detected ==="
  git diff --cached --stat
  echo ""
  git diff --cached --name-only
  echo ""
  echo "STATUS: Changes staged but NOT committed."
  echo ""
  echo "To review full diff:  cd $SKILL_DIR && git diff --cached"
  echo "To accept changes:    cd $SKILL_DIR && git commit -m 'Update from upstream'"
  echo "To reject changes:    cd $SKILL_DIR && git checkout ."
else
  # Initial commit for new skills
  git commit -q -m "Initial install from $URL"
  echo ""
  echo "Done! Installed to $SKILL_DIR"
  ls -la "$SKILL_DIR"
fi
