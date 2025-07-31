# Claude Code Configuration

## Project Overview
This repository contains AI development setup tools and configurations.

## Important Directories
- `.ai-setup/` - Main configuration directory containing:
  - `agents/` - Custom AI agents
  - `commands/` - Slash commands for Claude
  - `hooks/` - Post-tool-use hooks
  - `prompts/` - AI prompts
  - `rules/` - AI behavior rules
  - `scripts/` - Setup and utility scripts

- `.claude/` - Claude-specific configurations (created by setup script)

## File Visibility
Please ensure hidden files (those starting with `.`) are visible when working in this repository, as most configuration is stored in dotfiles and dotfolders.

## Setup Instructions
Run the setup script to configure AI development tools:
```bash
bash -c "$(curl -fsSL https://gist.githubusercontent.com/pr0j3c7t0dd/0b1d8d820e9357bae7ccc4938eba56e8/raw/setup-ai-dev.sh)"
```