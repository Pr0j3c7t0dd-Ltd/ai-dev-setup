#!/bin/bash

set -e

REPO_URL="https://github.com/Pr0j3c7t0dd-Ltd/ai-dev-setup"
BRANCH="main"

echo "🤖 AI Development Setup Script"
echo "=============================="
echo ""

if [ ! -d ".git" ]; then
    echo "❌ Error: This script must be run from the root of a git repository."
    exit 1
fi

echo "📋 This script will set up your repository for AI development by:"
echo "  - Optionally setting up a .devcontainer"
echo "  - Copying AI rules, prompts, hooks, agents, and commands"
echo "  - Setting up .claude directory with hooks, agents, and commands"
echo "  - Copying helper scripts"
echo "  - Optionally adding a product requirements submodule"
echo ""

read -p "📦 Would you like to set up a .devcontainer? (y/n): " SETUP_DEVCONTAINER
if [[ "$SETUP_DEVCONTAINER" =~ ^[Yy]$ ]]; then
    echo "⚙️  Setting up .devcontainer..."
    
    if [ -d ".devcontainer" ]; then
        echo "⚠️  .devcontainer already exists. Backing up to .devcontainer.backup..."
        mv .devcontainer .devcontainer.backup
    fi
    
    echo "📥 Cloning Anthropic Claude Code .devcontainer best practices..."
    git clone --depth 1 https://github.com/anthropics/claude-code.git temp-claude-code
    
    if [ -d "temp-claude-code/.devcontainer" ]; then
        cp -r temp-claude-code/.devcontainer .
        echo "✅ .devcontainer setup complete"
    else
        echo "⚠️  Warning: .devcontainer not found in claude-code repository"
    fi
    
    rm -rf temp-claude-code
fi

echo ""
echo "📥 Downloading AI development resources..."

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "📦 Cloning ai-dev-setup repository..."
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/ai-dev-setup" 2>/dev/null || {
    echo "❌ Error: Failed to clone repository. Please check your internet connection."
    exit 1
}

echo "📋 Copying AI rules..."
if [ -d "$TEMP_DIR/ai-dev-setup/.ai-setup/rules" ]; then
    mkdir -p .raw-ai-rules
    cp -r "$TEMP_DIR/ai-dev-setup/.ai-setup/rules/"* .raw-ai-rules/
    echo "✅ AI rules copied"
else
    echo "⚠️  Warning: rules folder not found in repository"
fi

echo "📋 Copying AI prompts..."
if [ -d "$TEMP_DIR/ai-dev-setup/.ai-setup/prompts" ]; then
    mkdir -p .raw-ai-prompts
    cp -r "$TEMP_DIR/ai-dev-setup/.ai-setup/prompts/"* .raw-ai-prompts/
    echo "✅ AI prompts copied"
else
    echo "⚠️  Warning: prompts folder not found in repository"
fi

echo "📋 Copying scripts folder..."
if [ -d "$TEMP_DIR/ai-dev-setup/.ai-setup/scripts" ]; then
    if [ ! -d "scripts" ]; then
        mkdir scripts
    fi
    cp -r "$TEMP_DIR/ai-dev-setup/.ai-setup/scripts/"* scripts/
    echo "✅ scripts copied"
else
    echo "⚠️  Warning: scripts folder not found in repository"
fi

echo "📋 Copying AI hooks..."
if [ -d "$TEMP_DIR/ai-dev-setup/.ai-setup/hooks" ]; then
    mkdir -p .raw-ai-hooks
    cp -r "$TEMP_DIR/ai-dev-setup/.ai-setup/hooks/"* .raw-ai-hooks/
    echo "✅ AI hooks copied (includes strict-code-linter hook)"
else
    echo "⚠️  Warning: hooks folder not found in repository"
fi

echo "📋 Copying AI agents..."
if [ -d "$TEMP_DIR/ai-dev-setup/.ai-setup/agents" ]; then
    mkdir -p .raw-ai-agents
    cp -r "$TEMP_DIR/ai-dev-setup/.ai-setup/agents/"* .raw-ai-agents/
    echo "✅ AI agents copied (includes strict-code-linter agent)"
else
    echo "⚠️  Warning: agents folder not found in repository"
fi

echo "📋 Copying AI commands..."
if [ -d "$TEMP_DIR/ai-dev-setup/.ai-setup/commands" ]; then
    mkdir -p .raw-ai-commands
    cp -r "$TEMP_DIR/ai-dev-setup/.ai-setup/commands/"* .raw-ai-commands/
    echo "✅ AI commands copied (slash commands)"
else
    echo "⚠️  Warning: commands folder not found in repository"
fi

echo "🔧 Setting up .claude directory structure..."
mkdir -p .claude/hooks .claude/agents .claude/commands

if [ -f ".raw-ai-hooks/hooks.json" ]; then
    cp .raw-ai-hooks/hooks.json .claude/hooks/
    echo "✅ Hooks configuration copied to .claude/hooks/"
fi

if [ -d ".raw-ai-agents" ]; then
    cp -r .raw-ai-agents/* .claude/agents/
    echo "✅ All agents copied to .claude/agents/"
fi

if [ -d ".raw-ai-commands" ]; then
    cp -r .raw-ai-commands/* .claude/commands/
    echo "✅ All slash commands copied to .claude/commands/"
fi

echo ""
read -p "📚 Would you like to add a 'product requirements' git submodule? (y/n): " ADD_SUBMODULE
if [[ "$ADD_SUBMODULE" =~ ^[Yy]$ ]]; then
    read -p "📍 Enter the git repository URL for the product requirements: " SUBMODULE_URL
    
    if [ -n "$SUBMODULE_URL" ]; then
        echo "➕ Adding product requirements submodule..."
        git submodule add "$SUBMODULE_URL" product-requirements || {
            echo "⚠️  Warning: Failed to add submodule. It may already exist or the URL may be invalid."
        }
        git submodule update --init --recursive
        echo "✅ Product requirements submodule added"
    else
        echo "⚠️  No URL provided, skipping submodule addition"
    fi
fi

echo ""
echo "🎉 AI development setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Review the contents of .raw-ai-rules, .raw-ai-prompts, .raw-ai-hooks, .raw-ai-agents, and .raw-ai-commands"
echo "  2. Customize the rules, prompts, hooks, agents, and slash commands for your project"
echo "  3. The .claude directory has been set up with hooks, agents, and commands"
echo "  4. The strict-code-linter agent and hook are configured to run after file updates"
echo "  5. If you set up a .devcontainer, rebuild your container"
echo ""
echo "💡 Tip: Consider committing these changes to your repository"