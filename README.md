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

> **Note**: This script is hosted as a public GitHub Gist while the main repository remains private. You'll need to update the gist with the new script from `.ai-setup/scripts/setup-ai-dev.sh`.

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
- PostToolUse hooks that play sounds after Bash commands and run lint/typecheck on file edits
- Notification hooks that play sounds for notifications
- Stop and SubagentStop hooks that play sounds when operations complete
- Custom agents in the `.ai-setup/agents` folder
- All configurations are automatically set up in the `.claude` directory structure

## Audio Passthrough for DevContainers (macOS)

If you're using a devcontainer and want audio passthrough support, you can run the dedicated PulseAudio setup script:

```bash
bash .ai-setup/scripts/setup-pulseaudio-passthrough.sh
```

This script will:
- Install and configure PulseAudio on macOS with network audio support
- Create audio tools installation scripts for the container
- Configure your devcontainer.json for audio passthrough
- Set up a universal `afplay` wrapper that works in both macOS and Linux environments

**Note**: This is currently only supported on macOS hosts.

## Requirements

- Git repository (the script must be run from a git repo root)
- Bash shell
- Internet connection to download resources