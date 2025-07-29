# ai-dev-setup

A repository containing tools and configurations to set up projects for AI-assisted development.

## Quick Start

To set up AI development tools in your repository, run this command from your project root:

```bash
bash -c "$(curl -fsSL https://gist.githubusercontent.com/pr0j3c7t0dd/0b1d8d820e9357bae7ccc4938eba56e8/raw/setup-ai-dev.sh)"
```

Or if you prefer wget:

```bash
bash -c "$(wget -qO- https://gist.githubusercontent.com/pr0j3c7t0dd/0b1d8d820e9357bae7ccc4938eba56e8/raw/setup-ai-dev.sh)"
```

> **Note**: This script is hosted as a public GitHub Gist while the main repository remains private. See [create-gist-instructions.md](scripts/create-gist-instructions.md) for setup details.

## What This Does

The setup script will:

1. **Optional .devcontainer Setup** - Clones the Anthropic Claude Code .devcontainer best practices
2. **AI Rules** - Copies `.raw-ai-rules` folder with AI development guidelines
3. **AI Prompts** - Copies `.raw-ai-prompts` folder with useful prompts
4. **Scripts** - Copies helper scripts for AI development workflows
5. **AI Hooks** - Copies `.raw-ai-hooks` folder with PostToolUse hooks (includes strict-code-linter)
6. **AI Agents** - Copies `.raw-ai-agents` folder with custom agents (includes strict-code-linter)
7. **Claude Directory Setup** - Automatically sets up `.claude/hooks` and `.claude/agents` directories
8. **Optional Product Requirements** - Adds a git submodule for product requirements documentation

### Hooks and Agents Configuration

The setup includes:
- A `hooks.json` file that configures the strict-code-linter to automatically run after file updates
- The `strict-code-linter` agent that reviews code for style violations, typos, and inconsistencies
- Both are automatically copied to the correct `.claude` directory structure for immediate use

## Requirements

- Git repository (the script must be run from a git repo root)
- Bash shell
- Internet connection to download resources