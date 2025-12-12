# Skill Manager for Claude Code

A Claude Code skill that manages other skills - install, update, rename, and uninstall skills directly from GitHub repositories, all through natural conversation.

## Features

- **Install skills from GitHub** - Point to any skill directory in a GitHub repo
- **Version tracking** - Each skill is a git repository with full change history
- **Update with review** - See diffs before accepting upstream changes
- **Bulk updates** - Update all managed skills at once
- **Rename & uninstall** - Full lifecycle management

## Installation

```bash
git clone https://github.com/ashimoon/claude-skill-manager ~/.claude/skills/skill-manager
```

Restart Claude Code to load the skill.

## Usage

Just talk to Claude Code:

- "Install this skill: https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev/skills/hook-development"
- "List my installed skills"
- "Update the hook-development skill"
- "Update all my skills"
- "Rename hook-development to hooks"
- "Uninstall the hooks skill"

Claude handles the rest.

## Requirements

- `curl`
- `jq`
- `git`

## License

MIT
