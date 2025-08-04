#!/bin/bash

set -e

# Version number for the setup script
SCRIPT_VERSION="1.0.8"

REPO_URL="https://github.com/Pr0j3c7t0dd-Ltd/ai-dev-setup"
BRANCH="main"

echo "🤖 AI Development Setup Script v${SCRIPT_VERSION}"
echo "=============================="
echo ""

if [ ! -d ".git" ]; then
    echo "❌ Error: This script must be run from the root of a git repository."
    exit 1
fi

echo "📋 This script will set up your repository for AI development by:"
echo "  - Optionally setting up a .devcontainer"
echo "  - Copying AI rules, prompts, agents, and commands"
echo "  - Setting up .claude directory with agents and commands"
echo "  - Making helper scripts executable in .ai-setup/scripts/"
echo "  - Copying .claudeconfig and settings.json for Claude IDE integration"
echo "  - Optionally adding a product requirements submodule"
echo "  - Replacing [PRODUCT_REQS_VAULT_DIR] placeholders with actual path"
echo "  - Syncing AI rules across different IDEs (Cursor, Windsurf, Claude)"
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

echo "📦 Cloning ai-dev-setup repository (v${SCRIPT_VERSION})..."
# Force fresh clone to avoid caching issues
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/ai-dev-setup" 2>/dev/null || {
    echo "❌ Error: Failed to clone repository. Please check your internet connection."
    exit 1
}

# Check if there's a newer version available
if [ -f "$TEMP_DIR/ai-dev-setup/.ai-setup/scripts/setup-ai-dev.sh" ]; then
    REMOTE_VERSION=$(grep "^SCRIPT_VERSION=" "$TEMP_DIR/ai-dev-setup/.ai-setup/scripts/setup-ai-dev.sh" | cut -d'"' -f2)
    if [ "$REMOTE_VERSION" != "$SCRIPT_VERSION" ]; then
        echo ""
        echo "⚠️  A newer version of this script is available (v${REMOTE_VERSION})"
        echo "   Please download the latest version from:"
        echo "   curl -fsSL https://raw.githubusercontent.com/Pr0j3c7t0dd-Ltd/ai-dev-setup/main/.ai-setup/scripts/setup-ai-dev.sh | bash"
        echo ""
    fi
fi

echo "📋 Copying .ai-setup folder..."
if [ -d "$TEMP_DIR/ai-dev-setup/.ai-setup" ]; then
    cp -r "$TEMP_DIR/ai-dev-setup/.ai-setup" .
    echo "✅ .ai-setup folder copied"
else
    echo "❌ Error: .ai-setup folder not found in repository"
    exit 1
fi

echo "🔧 Setting up .claude directory structure..."
mkdir -p .claude/agents .claude/commands

echo "📋 Moving AI resources to final locations..."

if [ -d ".ai-setup/agents" ] && [ "$(ls -A .ai-setup/agents/)" ]; then
    cp -r .ai-setup/agents/* .claude/agents/
    echo "✅ Agents copied to .claude/agents/"
fi

if [ -d ".ai-setup/commands" ] && [ "$(ls -A .ai-setup/commands/)" ]; then
    cp -r .ai-setup/commands/* .claude/commands/
    echo "✅ Commands copied to .claude/commands/"
fi

if [ -d ".ai-setup/scripts" ]; then
    # Make scripts executable
    chmod +x .ai-setup/scripts/*.sh 2>/dev/null || true
    if [ -f ".ai-setup/scripts/afplay" ]; then
        chmod +x .ai-setup/scripts/afplay
    fi
    echo "✅ Scripts in .ai-setup/scripts/ made executable"
    echo "ℹ️  Scripts are available in .ai-setup/scripts/ (not copied to project root)"
fi

if [ -f ".ai-setup/ide/claude/.claudeconfig" ]; then
    cp .ai-setup/ide/claude/.claudeconfig .
    echo "✅ .claudeconfig copied to root directory"
fi

if [ -f ".ai-setup/ide/claude/settings.json" ]; then
    # Check if we're in a container environment
    if [ -f "/.dockerenv" ] || [ -n "$DEVCONTAINER" ] || [ -n "$CODESPACES" ]; then
        # Use devcontainer-specific settings if available
        if [ -f ".ai-setup/ide/claude/settings-devcontainer.json" ]; then
            cp .ai-setup/ide/claude/settings-devcontainer.json .claude/settings.json
            echo "✅ settings-devcontainer.json copied to .claude/settings.json (container environment detected)"
            
            # If we're in a container and afplay isn't in PATH, create a symlink
            if ! command -v afplay &> /dev/null && [ -f ".ai-setup/scripts/afplay" ]; then
                echo "🔧 Creating afplay symlink for container environment..."
                if [ -w "/usr/local/bin" ]; then
                    ln -sf "$(pwd)/.ai-setup/scripts/afplay" /usr/local/bin/afplay
                    echo "✅ afplay symlink created in /usr/local/bin/"
                else
                    echo "⚠️  Cannot create symlink in /usr/local/bin/ (no write permission)"
                    echo "   You may need to rebuild the container or run:"
                    echo "   sudo ln -sf $(pwd)/.ai-setup/scripts/afplay /usr/local/bin/afplay"
                fi
            fi
        else
            cp .ai-setup/ide/claude/settings.json .claude/
            echo "✅ settings.json copied to .claude directory"
        fi
    else
        cp .ai-setup/ide/claude/settings.json .claude/
        echo "✅ settings.json copied to .claude directory"
    fi
fi

echo ""
read -p "📚 Would you like to add a 'product requirements' git submodule? (y/n): " ADD_SUBMODULE
if [[ "$ADD_SUBMODULE" =~ ^[Yy]$ ]]; then
    read -p "📍 Enter the git repository URL for the product requirements: " SUBMODULE_URL
    
    if [ -n "$SUBMODULE_URL" ]; then
        echo "➕ Adding product requirements submodule..."
        git submodule add "$SUBMODULE_URL" || {
            echo "⚠️  Warning: Failed to add submodule. It may already exist or the URL may be invalid."
        }
        git submodule update --init --recursive
        
        # Find the actual directory name created by git submodule
        SUBMODULE_DIR=$(git submodule status | grep -E "^[-+ ]" | awk '{print $2}' | tail -n 1)
        
        if [ -n "$SUBMODULE_DIR" ]; then
            echo "✅ Product requirements submodule added as: $SUBMODULE_DIR"
            
            # Replace [PRODUCT_REQS_VAULT_DIR] placeholder with relative path
            echo "🔄 Updating references to product requirements directory..."
            
            # Find and replace in all files
            find . -type f -name "*.md" -o -name "*.txt" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" | while read -r file; do
                if grep -q "\[PRODUCT_REQS_VAULT_DIR\]" "$file" 2>/dev/null; then
                    # Use sed to replace the placeholder
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        # macOS sed requires backup extension
                        sed -i '' "s|\[PRODUCT_REQS_VAULT_DIR\]|$SUBMODULE_DIR|g" "$file"
                    else
                        # Linux sed
                        sed -i "s|\[PRODUCT_REQS_VAULT_DIR\]|$SUBMODULE_DIR|g" "$file"
                    fi
                    echo "  ✅ Updated: $file"
                fi
            done
            
            echo "✅ Product requirements path references updated"
        else
            echo "⚠️  Warning: Could not determine submodule directory name"
        fi
    else
        echo "⚠️  No URL provided, skipping submodule addition"
    fi
fi

echo ""
echo "🔄 Running sync-rules.sh to sync AI rules across different IDEs..."
if [ -f ".ai-setup/scripts/sync-rules.sh" ]; then
    # Make sure the script is executable
    chmod +x .ai-setup/scripts/sync-rules.sh
    # Run the sync script
    ./.ai-setup/scripts/sync-rules.sh || {
        echo "⚠️  Warning: sync-rules.sh encountered an error but setup will continue"
    }
else
    echo "⚠️  Warning: sync-rules.sh not found, skipping rules sync"
fi

echo ""
echo "🎉 AI development setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Review the contents of the .ai-setup folder"
echo "  2. The .claude directory has been set up with agents, commands, and settings"
echo "  3. Scripts are available in .ai-setup/scripts/ (executable)"
echo "  4. AI rules have been synced to .cursor, .windsurf, and CLAUDE.md"
echo "  5. Customize the rules, prompts, agents, and slash commands in .ai-setup"
if [ -f "/.dockerenv" ] || [ -n "$DEVCONTAINER" ] || [ -n "$CODESPACES" ]; then
    echo "  6. ⚠️  If audio isn't working, rebuild your container to install audio tools"
else
    echo "  6. If you set up a .devcontainer, rebuild your container"
fi
echo ""
echo "💡 Tip: Consider committing these changes to your repository"