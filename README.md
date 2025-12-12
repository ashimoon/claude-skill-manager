# Skill Manager for Claude Code

A Claude Code skill that manages other skills - install, update, rename, and uninstall skills directly from GitHub repositories, all through natural conversation.

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

## How It Works

This is a **skill that teaches Claude how to manage skills**. When you ask Claude to install or update a skill, it reads the instructions in `SKILL.md` and knows exactly which bash scripts to run.

```
┌─────────────────────────────────────────────────────────────────┐
│  You: "Install this skill: github.com/foo/bar/tree/.../skill"   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Claude reads SKILL.md → learns how to use install-skill.sh     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Script downloads files, creates git repo, commits              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Skill installed! Restart Claude Code to activate               │
└─────────────────────────────────────────────────────────────────┘
```

### The Magic: Two Installation Modes

**1. Root repo URL** → Uses `git clone`
```
github.com/owner/repo
```
Full repository cloning with native git. Updates use `git pull`.

**2. Subpath URL** → Uses GitHub API
```
github.com/owner/repo/tree/main/path/to/skill
```
Many skills live nested deep inside larger repositories. Git's sparse checkout preserves the original directory structure, so you'd end up with `skill-name/path/to/skill/SKILL.md` instead of `skill-name/SKILL.md`. Flattening requires `git subtree split` which adds complexity and makes updates harder. Instead, we use GitHub's Contents API to download just the files we need directly to the root. Simple, and each skill becomes its own independent git repository.

### Version Control Built In

Every installed skill is a local git repository:

```
~/.claude/skills/
├── hook-development/     ← git repo with full history
│   ├── .git/
│   ├── .skill-manager.json   ← tracks source URL
│   └── SKILL.md
├── frontend-design/      ← another git repo
└── skill-manager/        ← this skill (manages itself!)
```

When you update, changes are **staged but not committed** - you review the diff first:

```
You: "Update my skills"

Claude: Found changes in hook-development:
        +  Added new hook type
        ~  Modified example code

        Accept or reject?
```

### Self-Managing

The skill-manager can update itself. It tracks its own source and pulls updates like any other skill.

## Features

- **Install skills from GitHub** - Point to any skill directory in a GitHub repo
- **Version tracking** - Each skill is a git repository with full change history
- **Update with review** - See diffs before accepting upstream changes
- **Bulk updates** - Update all managed skills at once
- **Rename & uninstall** - Full lifecycle management
- **Local change protection** - Won't overwrite uncommitted modifications

## Requirements

- `curl` - for downloading files via GitHub API
- `jq` - for parsing JSON responses
- `git` - for version tracking

## Architecture

```
skill-manager/
├── SKILL.md              # Instructions for Claude (the magic!)
├── README.md             # You are here
└── scripts/
    ├── install-skill.sh  # Handles both clone and API modes
    ├── update-skill.sh   # Fetch + stage changes for review
    ├── update-all-skills.sh
    ├── list-skills.sh
    ├── uninstall-skill.sh
    ├── rename-skill.sh
    ├── skill-accept.sh   # Commit staged changes
    └── skill-reject.sh   # Discard staged changes
```

The `SKILL.md` file is the key - it contains structured instructions that Claude reads to understand:
- Which script to run for each user request
- How to handle conflicts and edge cases
- What to tell the user at each step

## License

MIT
