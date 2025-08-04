#!/bin/bash

set -e

echo "🔊 PulseAudio Passthrough Setup for DevContainers"
echo "================================================"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  Audio passthrough setup is currently only supported on macOS"
    exit 1
fi

# Check if PulseAudio is installed
if ! command -v pulseaudio &> /dev/null; then
    echo "📦 Installing PulseAudio via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install pulseaudio
        echo "✅ PulseAudio installed"
        
        # Create PulseAudio configuration directory
        echo "📝 Creating PulseAudio configuration..."
        mkdir -p ~/.config/pulse
        
        # Detect correct path for system defaults (Apple Silicon vs Intel)
        if [ -f "/opt/homebrew/etc/pulse/default.pa" ]; then
            PULSE_DEFAULT="/opt/homebrew/etc/pulse/default.pa"
        elif [ -f "/usr/local/etc/pulse/default.pa" ]; then
            PULSE_DEFAULT="/usr/local/etc/pulse/default.pa"
        else
            PULSE_DEFAULT="/etc/pulse/default.pa"
        fi
        
        cat > ~/.config/pulse/default.pa << EOF
# Load system defaults
.include $PULSE_DEFAULT

# Load TCP module for network audio (Docker containers)
load-module module-native-protocol-tcp

# Set exit idle time to never
set-prop module-suspend-on-idle timeout 0
EOF
        echo "✅ PulseAudio configuration created"
        
        # Stop any existing PulseAudio service
        brew services stop pulseaudio 2>/dev/null || true
        
        # Start PulseAudio as a service
        echo "🔊 Starting PulseAudio as a service..."
        brew services start pulseaudio
        
        # Wait for service to start
        sleep 3
        
        # Verify PulseAudio is running
        if pulseaudio --check 2>/dev/null; then
            echo "✅ PulseAudio service started with network audio enabled"
            echo "✅ PulseAudio will start automatically on reboot"
        else
            echo "⚠️  PulseAudio service may not have started correctly"
            echo "   Try: brew services restart pulseaudio"
        fi
    else
        echo "⚠️  Homebrew not found. Please install PulseAudio manually:"
        echo "    brew install pulseaudio"
        exit 1
    fi
else
    echo "✅ PulseAudio already installed"
    
    # Ensure configuration exists
    if [ ! -f ~/.config/pulse/default.pa ]; then
        echo "📝 Creating PulseAudio configuration..."
        mkdir -p ~/.config/pulse
        
        # Detect correct path for system defaults (Apple Silicon vs Intel)
        if [ -f "/opt/homebrew/etc/pulse/default.pa" ]; then
            PULSE_DEFAULT="/opt/homebrew/etc/pulse/default.pa"
        elif [ -f "/usr/local/etc/pulse/default.pa" ]; then
            PULSE_DEFAULT="/usr/local/etc/pulse/default.pa"
        else
            PULSE_DEFAULT="/etc/pulse/default.pa"
        fi
        
        cat > ~/.config/pulse/default.pa << EOF
# Load system defaults
.include $PULSE_DEFAULT

# Load TCP module for network audio (Docker containers)
load-module module-native-protocol-tcp

# Set exit idle time to never
set-prop module-suspend-on-idle timeout 0
EOF
        echo "✅ PulseAudio configuration created"
    fi
    
    # Check if PulseAudio service is running
    if brew services list | grep -q "pulseaudio.*started"; then
        echo "✅ PulseAudio service already running"
    else
        echo "🔊 Starting PulseAudio as a service..."
        brew services start pulseaudio
        sleep 3
        if pulseaudio --check 2>/dev/null; then
            echo "✅ PulseAudio service started"
            echo "✅ PulseAudio will start automatically on reboot"
        else
            echo "⚠️  PulseAudio service may not have started correctly"
            echo "   Try: brew services restart pulseaudio"
        fi
    fi
fi

# Create audio setup scripts
echo "📝 Creating audio configuration scripts..."
mkdir -p .devcontainer/audio-setup

# Also create a simple inline installation approach for compatibility
echo "📝 Creating inline audio installer..."
cat > .devcontainer/install-audio.sh << 'EOF'
#!/bin/bash
# Direct audio tools installation
echo "Installing audio tools..."
apt-get update && apt-get install -y \
    pulseaudio-utils \
    sox \
    libsox-fmt-all \
    mpg123 \
    ffmpeg \
    alsa-utils \
    bc \
    && rm -rf /var/lib/apt/lists/*

# Create afplay wrapper inline
cat > /usr/local/bin/afplay << 'AFPLAY_EOF'
#!/bin/bash
# Universal afplay wrapper - works on macOS and Linux
if [ $# -eq 0 ]; then
    echo "Usage: afplay <audiofile> [options]"
    exit 1
fi

# Linux/container environment
FILE=""
VOLUME=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --volume|-v)
            VOLUME="$2"
            shift 2
            ;;
        *)
            if [ -z "$FILE" ]; then
                FILE="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "Error: Audio file not found: $FILE"
    exit 1
fi

# Try paplay first for AIFF/WAV
if command -v paplay &> /dev/null; then
    if [ -n "$VOLUME" ]; then
        paplay --volume=$(echo "$VOLUME * 65536" | bc | cut -d. -f1) "$FILE" 2>/dev/null
    else
        paplay "$FILE" 2>/dev/null
    fi
elif command -v play &> /dev/null; then
    if [ -n "$VOLUME" ]; then
        play -v "$VOLUME" "$FILE" 2>/dev/null
    else
        play "$FILE" 2>/dev/null
    fi
else
    echo "Error: No audio player found"
    exit 1
fi
AFPLAY_EOF

chmod +x /usr/local/bin/afplay
echo "Audio tools installation complete!"
EOF
chmod +x .devcontainer/install-audio.sh

# Create the install-audio-tools.sh script
cat > .devcontainer/audio-setup/install-audio-tools.sh << 'EOF'
#!/bin/bash
# Install audio tools in the container
# This script is designed to run as root during container creation

apt-get update && apt-get install -y \
    pulseaudio-utils \
    sox \
    libsox-fmt-all \
    mpg123 \
    ffmpeg \
    alsa-utils \
    bc \
    && rm -rf /var/lib/apt/lists/*
EOF
chmod +x .devcontainer/audio-setup/install-audio-tools.sh

# Create the universal afplay wrapper script
cat > .devcontainer/audio-setup/afplay << 'EOF'
#!/bin/bash
# Universal afplay wrapper - works on macOS and Linux
# On macOS: uses native afplay
# On Linux: uses paplay/sox/mpg123

if [ $# -eq 0 ]; then
    echo "Usage: afplay <audiofile> [options]"
    exit 1
fi

# Check if we're on macOS and have native afplay
if [[ "$OSTYPE" == "darwin"* ]] && command -v /usr/bin/afplay &> /dev/null; then
    # Use native macOS afplay
    exec /usr/bin/afplay "$@"
fi

# Linux/container environment - parse arguments
FILE=""
VOLUME=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --volume|-v)
            VOLUME="$2"
            shift 2
            ;;
        *)
            if [ -z "$FILE" ]; then
                FILE="$1"
            else
                ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

if [ -z "$FILE" ]; then
    echo "Error: No audio file specified"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

# Get file extension
EXT="${FILE##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

# Set volume for Linux audio players (0.0 to 1.0 scale)
if [ -n "$VOLUME" ]; then
    # Convert volume to percentage for some players
    VOL_PERCENT=$(echo "$VOLUME * 100" | bc | cut -d. -f1)
fi

# Try to play using paplay for WAV files
if [ "$EXT_LOWER" = "wav" ] || [ "$EXT_LOWER" = "aiff" ]; then
    if command -v paplay &> /dev/null; then
        if [ -n "$VOLUME" ]; then
            paplay --volume=$(echo "$VOLUME * 65536" | bc | cut -d. -f1) "$FILE"
        else
            paplay "$FILE"
        fi
    elif command -v aplay &> /dev/null; then
        aplay "$FILE"
    else
        echo "Error: No audio player found for WAV/AIFF files"
        exit 1
    fi
else
    # For other formats, use sox or mpg123
    if command -v play &> /dev/null; then
        if [ -n "$VOLUME" ]; then
            play -v "$VOLUME" "$FILE" 2>/dev/null
        else
            play "$FILE" 2>/dev/null
        fi
    elif [ "$EXT_LOWER" = "mp3" ] && command -v mpg123 &> /dev/null; then
        if [ -n "$VOL_PERCENT" ]; then
            mpg123 -q -f $(echo "$VOL_PERCENT * 327" | bc | cut -d. -f1) "$FILE"
        else
            mpg123 -q "$FILE"
        fi
    elif command -v ffplay &> /dev/null; then
        if [ -n "$VOLUME" ]; then
            ffplay -nodisp -autoexit -volume "$VOL_PERCENT" "$FILE" 2>/dev/null
        else
            ffplay -nodisp -autoexit "$FILE" 2>/dev/null
        fi
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
    
    # Create a backup of the original file
    cp .devcontainer/devcontainer.json .devcontainer/devcontainer.json.backup
    
    # Use Python to properly update the JSON file
    python3 << 'PYTHON_EOF'
import json
import os

devcontainer_path = '.devcontainer/devcontainer.json'

try:
    with open(devcontainer_path, 'r') as f:
        config = json.load(f)
    
    # Add or update onCreateCommand to install audio tools (runs as root)
    on_create_cmd = "bash /workspaces/${localWorkspaceFolderBasename}/.devcontainer/install-audio.sh"
    
    if 'onCreateCommand' in config:
        # If there's already an onCreateCommand, append to it
        if isinstance(config['onCreateCommand'], str):
            config['onCreateCommand'] = config['onCreateCommand'] + " && " + on_create_cmd
        elif isinstance(config['onCreateCommand'], list):
            config['onCreateCommand'].append(on_create_cmd)
    else:
        config['onCreateCommand'] = on_create_cmd
    
    # Add or update runArgs
    pulse_env = ["--env", "PULSE_SERVER=host.docker.internal"]
    if 'runArgs' not in config:
        config['runArgs'] = []
    
    # Check if PULSE_SERVER env is already set
    pulse_exists = False
    for i in range(0, len(config['runArgs'])-1):
        if config['runArgs'][i] == "--env" and config['runArgs'][i+1].startswith("PULSE_SERVER="):
            pulse_exists = True
            break
    
    if not pulse_exists:
        config['runArgs'].extend(pulse_env)
    
    # Handle mounts
    if 'mounts' not in config:
        config['mounts'] = []
    
    # Remove any existing X11 mounts
    x11_mount_pattern = "/tmp/.X11-unix"
    config['mounts'] = [mount for mount in config['mounts'] if x11_mount_pattern not in mount]
    
    # Add PulseAudio config mount for authentication
    import os
    home = os.path.expanduser("~")
    pulse_config_mount = f"source={home}/.config/pulse,target=/home/node/.config/pulse,type=bind,consistency=cached"
    
    # Check if mount already exists
    pulse_mount_exists = any("/.config/pulse" in mount for mount in config['mounts'])
    if not pulse_mount_exists:
        config['mounts'].append(pulse_config_mount)
        print("✅ Added PulseAudio config mount for authentication")
    
    # Write the updated config back
    with open(devcontainer_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print("✅ devcontainer.json updated successfully")
    
except json.JSONDecodeError:
    print("⚠️  Error: devcontainer.json is not valid JSON")
    print("Please check the file and manually add the audio configuration")
except Exception as e:
    print(f"⚠️  Error updating devcontainer.json: {e}")
    print("Please manually add the following to your .devcontainer/devcontainer.json:")
    print('  "onCreateCommand": "bash /workspaces/${localWorkspaceFolderBasename}/.devcontainer/install-audio.sh",')
    print('  "runArgs": ["--env", "PULSE_SERVER=host.docker.internal"],')
PYTHON_EOF

    if [ $? -eq 0 ]; then
        echo "📝 A backup of your original devcontainer.json was saved as devcontainer.json.backup"
    fi
else
    echo "⚠️  No .devcontainer/devcontainer.json found. Please create one first."
fi

echo "✅ Audio passthrough setup complete"
echo ""
echo "📝 PulseAudio daemon has been started with network audio support"
echo ""
echo "🔄 Container rebuild required: YES"
echo "  - You need to rebuild your container for the audio changes to take effect"
echo "  - Use: Dev Containers: Rebuild Container (in VS Code)"
echo "  - Or: docker-compose down && docker-compose up --build"
echo ""
echo "🔧 Container audio setup:"
echo "  - PULSE_SERVER environment variable set to host.docker.internal"
echo "  - PulseAudio config mounted for authentication (~/.config/pulse)"
echo "  - Audio tools will be installed on container creation"
echo ""
echo "ℹ️  To test audio from inside an active container (after rebuild):"
echo "    # Test with system sounds:"
echo "    speaker-test -c 2 -l 1 -t wav"
echo "    # Or test with project sounds using the afplay wrapper:"
echo "    afplay .ai-setup/sounds/Glass.aiff --volume 0.5"
echo "    afplay .ai-setup/sounds/Hero.aiff --volume 0.3"
echo ""
echo "    # If afplay is not found, you have three options:"
echo "    # Option 1: Run as root user from outside the container:"
echo "    # First, find your container name/ID:"
echo "    docker ps  # Look for your devcontainer"
echo "    # Then run (replace CONTAINER_ID with actual ID from docker ps):"
echo "    docker exec -u root CONTAINER_ID bash -c \"apt-get update && apt-get install -y pulseaudio-utils sox libsox-fmt-all bc\""
echo "    docker exec -u root CONTAINER_ID cp /workspace/.devcontainer/audio-setup/afplay /usr/local/bin/"
echo "    docker exec -u root CONTAINER_ID chmod +x /usr/local/bin/afplay"
echo ""
echo "    # Option 2: If you have passwordless sudo in the container:"
echo "    sudo bash .devcontainer/audio-setup/install-audio-tools.sh"
echo "    sudo cp .devcontainer/audio-setup/afplay /usr/local/bin/"
echo ""
echo "    # Option 3: Rebuild the container (recommended)"
echo ""
echo "ℹ️  To test audio with a new container:"
echo "    docker run -it -e PULSE_SERVER=host.docker.internal \\"
echo "      -v ~/.config/pulse:/home/node/.config/pulse \\"
echo "      your-image speaker-test -c 2 -l 1 -t wav"
echo ""
echo "ℹ️  PulseAudio service management:"
echo "    brew services restart pulseaudio    # Restart the service"
echo "    brew services stop pulseaudio       # Stop the service"
echo "    brew services start pulseaudio      # Start the service"
echo "    brew services list                  # Check service status"
echo ""