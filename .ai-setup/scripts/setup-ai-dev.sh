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
echo "  - Copying AI rules, prompts, agents, and commands"
echo "  - Setting up .claude directory with agents and commands"
echo "  - Copying helper scripts"
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
    
    # Ask about PulseAudio installation for audio passthrough
    echo ""
    read -p "🔊 Would you like to install PulseAudio for audio passthrough from the devcontainer? (y/n): " SETUP_PULSEAUDIO
    if [[ "$SETUP_PULSEAUDIO" =~ ^[Yy]$ ]]; then
        echo "⚙️  Setting up audio passthrough for .devcontainer..."
        
        # Check if running on macOS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Check if PulseAudio is installed
            if ! command -v pulseaudio &> /dev/null; then
                echo "📦 Installing PulseAudio via Homebrew..."
                if command -v brew &> /dev/null; then
                    brew install pulseaudio
                    echo "✅ PulseAudio installed"
                    
                    # Start PulseAudio daemon with network module
                    echo "🔊 Starting PulseAudio daemon with network support..."
                    # Kill any existing PulseAudio instances first
                    pulseaudio --kill 2>/dev/null || true
                    sleep 1
                    # Start with TCP module for network audio
                    pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon
                    sleep 2
                    # Load anonymous auth module
                    pactl load-module module-native-protocol-tcp auth-anonymous=1 2>/dev/null || true
                    echo "✅ PulseAudio daemon started with network audio enabled"
                else
                    echo "⚠️  Homebrew not found. Please install PulseAudio manually:"
                    echo "    brew install pulseaudio"
                fi
            else
                echo "✅ PulseAudio already installed"
                # Check if daemon is running
                if ! pgrep -x pulseaudio > /dev/null; then
                    echo "🔊 Starting PulseAudio daemon with network support..."
                    pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon
                    sleep 2
                    pactl load-module module-native-protocol-tcp auth-anonymous=1 2>/dev/null || true
                    echo "✅ PulseAudio daemon started"
                else
                    echo "✅ PulseAudio daemon already running"
                    # Ensure network module is loaded
                    if ! pactl list modules | grep -q "module-native-protocol-tcp"; then
                        echo "🔊 Loading network audio module..."
                        pactl load-module module-native-protocol-tcp auth-anonymous=1 2>/dev/null || true
                        echo "✅ Network audio module loaded"
                    fi
                fi
            fi
            
            # Create audio setup scripts
            echo "📝 Creating audio configuration scripts..."
            mkdir -p .devcontainer/audio-setup
            
            # Create the install-audio-tools.sh script
            cat > .devcontainer/audio-setup/install-audio-tools.sh << 'EOF'
#!/bin/bash
# Install audio tools in the container
apt-get update && apt-get install -y \
    pulseaudio-utils \
    sox \
    libsox-fmt-all \
    mpg123 \
    ffmpeg \
    alsa-utils
EOF
            chmod +x .devcontainer/audio-setup/install-audio-tools.sh
            
            # Create the afplay wrapper script
            cat > .devcontainer/audio-setup/afplay << 'EOF'
#!/bin/bash
# afplay wrapper for Linux containers
# Mimics macOS afplay command using paplay/sox

if [ $# -eq 0 ]; then
    echo "Usage: afplay <audiofile>"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

# Get file extension
EXT="${FILE##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

# Try to play using paplay for WAV files
if [ "$EXT_LOWER" = "wav" ]; then
    if command -v paplay &> /dev/null; then
        paplay "$FILE"
    elif command -v aplay &> /dev/null; then
        aplay "$FILE"
    else
        echo "Error: No audio player found for WAV files"
        exit 1
    fi
else
    # For other formats, use sox or mpg123
    if command -v play &> /dev/null; then
        play "$FILE" 2>/dev/null
    elif [ "$EXT_LOWER" = "mp3" ] && command -v mpg123 &> /dev/null; then
        mpg123 -q "$FILE"
    elif command -v ffplay &> /dev/null; then
        ffplay -nodisp -autoexit "$FILE" 2>/dev/null
    else
        echo "Error: No suitable audio player found for $EXT files"
        exit 1
    fi
fi
EOF
            chmod +x .devcontainer/audio-setup/afplay
            
            # Update devcontainer.json to include audio setup
            if [ -f ".devcontainer/devcontainer.json" ]; then
                echo "📝 Updating devcontainer.json for audio support..."
                # This is a simple approach - in production you'd want to parse JSON properly
                echo ""
                echo "⚠️  Please manually add the following to your .devcontainer/devcontainer.json:"
                echo ""
                echo '  "postCreateCommand": "bash /workspaces/${localWorkspaceFolderBasename}/.devcontainer/audio-setup/install-audio-tools.sh && cp /workspaces/${localWorkspaceFolderBasename}/.devcontainer/audio-setup/afplay /usr/local/bin/",'
                echo ""
                echo '  "runArgs": ["--env", "PULSE_SERVER=host.docker.internal"],'
                echo ""
                echo '  "mounts": ["source=/tmp/.X11-unix,target=/tmp/.X11-unix,type=bind,consistency=cached"],'
                echo ""
            fi
            
            echo "✅ Audio passthrough setup complete"
            echo ""
            echo "📝 PulseAudio daemon has been started with network audio support"
            echo ""
            echo "ℹ️  If you need to restart PulseAudio manually:"
            echo "    pulseaudio --kill"
            echo "    pulseaudio --load=module-native-protocol-tcp --exit-idle-time=-1 --daemon"
            echo "    pactl load-module module-native-protocol-tcp auth-anonymous=1"
            echo ""
        else
            echo "⚠️  Audio passthrough setup is currently only supported on macOS"
        fi
    fi
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
    mkdir -p scripts
    [ "$(ls -A .ai-setup/scripts/)" ] && cp -r .ai-setup/scripts/* scripts/
    echo "✅ Scripts copied to scripts/"
fi

if [ -f ".ai-setup/ide/claude/.claudeconfig" ]; then
    cp .ai-setup/ide/claude/.claudeconfig .
    echo "✅ .claudeconfig copied to root directory"
fi

if [ -f ".ai-setup/ide/claude/settings.json" ]; then
    cp .ai-setup/ide/claude/settings.json .claude/
    echo "✅ settings.json copied to .claude directory"
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
echo "  3. Scripts have been copied to the scripts folder"
echo "  4. AI rules have been synced to .cursor, .windsurf, and CLAUDE.md"
echo "  5. Customize the rules, prompts, agents, and slash commands in .ai-setup"
echo "  6. If you set up a .devcontainer, rebuild your container"
echo ""
echo "💡 Tip: Consider committing these changes to your repository"