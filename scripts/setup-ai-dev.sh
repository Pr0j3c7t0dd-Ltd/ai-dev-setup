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
echo "  - Copying AI rules, prompts, hooks, and agents"
echo "  - Setting up .claude directory with hooks and agents"
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

echo "📋 Copying .raw-ai-rules folder..."
if [ -d "$TEMP_DIR/ai-dev-setup/.raw-ai-rules" ]; then
    cp -r "$TEMP_DIR/ai-dev-setup/.raw-ai-rules" .
    echo "✅ .raw-ai-rules copied"
else
    echo "⚠️  Warning: .raw-ai-rules folder not found in repository"
fi

echo "📋 Copying .raw-ai-prompts folder..."
if [ -d "$TEMP_DIR/ai-dev-setup/.raw-ai-prompts" ]; then
    cp -r "$TEMP_DIR/ai-dev-setup/.raw-ai-prompts" .
    echo "✅ .raw-ai-prompts copied"
else
    echo "⚠️  Warning: .raw-ai-prompts folder not found in repository"
fi

echo "📋 Copying scripts folder..."
if [ -d "$TEMP_DIR/ai-dev-setup/scripts" ]; then
    if [ ! -d "scripts" ]; then
        mkdir scripts
    fi
    cp -r "$TEMP_DIR/ai-dev-setup/scripts/"* scripts/
    echo "✅ scripts copied"
else
    echo "⚠️  Warning: scripts folder not found in repository"
fi

echo "📋 Copying .raw-ai-hooks folder..."
if [ -d "$TEMP_DIR/ai-dev-setup/.raw-ai-hooks" ]; then
    cp -r "$TEMP_DIR/ai-dev-setup/.raw-ai-hooks" .
    echo "✅ .raw-ai-hooks copied (includes strict-code-linter hook)"
else
    echo "⚠️  Warning: .raw-ai-hooks folder not found in repository"
fi

echo "📋 Copying .raw-ai-agents folder..."
if [ -d "$TEMP_DIR/ai-dev-setup/.raw-ai-agents" ]; then
    cp -r "$TEMP_DIR/ai-dev-setup/.raw-ai-agents" .
    echo "✅ .raw-ai-agents copied (includes strict-code-linter agent)"
else
    echo "⚠️  Warning: .raw-ai-agents folder not found in repository"
fi

echo "🔧 Setting up .claude directory structure..."
mkdir -p .claude/hooks .claude/agents

if [ -f ".raw-ai-hooks/hooks.json" ]; then
    cp .raw-ai-hooks/hooks.json .claude/hooks/
    echo "✅ Hooks configuration copied to .claude/hooks/"
fi

if [ -f ".raw-ai-agents/agent-strict-code-linter.md" ]; then
    cp .raw-ai-agents/agent-strict-code-linter.md .claude/agents/
    echo "✅ strict-code-linter agent copied to .claude/agents/"
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
echo "  1. Review the contents of .raw-ai-rules, .raw-ai-prompts, .raw-ai-hooks, and .raw-ai-agents"
echo "  2. Customize the rules, prompts, hooks, and agents for your project"
echo "  3. The .claude directory has been set up with hooks and agents"
echo "  4. The strict-code-linter agent and hook are configured to run after file updates"
echo "  5. If you set up a .devcontainer, rebuild your container"
echo ""
echo "💡 Tip: Consider committing these changes to your repository"