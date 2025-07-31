#!/bin/bash

# Test PulseAudio from Devcontainer
# This script tests the connection from a devcontainer to the host PulseAudio server

echo "🔊 PulseAudio Container Test Script"
echo "===================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✅ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 1. Check environment
echo "1. Checking container environment..."
if [ -f "/.dockerenv" ] || [ -n "$DEVCONTAINER" ] || [ -n "$CODESPACES" ]; then
    echo -e "${GREEN}✅ Running inside a container${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠️  Not running inside a container${NC}"
    echo "   This script is designed to run inside a devcontainer"
fi

echo ""

# 2. Check PULSE_SERVER environment variable
echo "2. Checking PULSE_SERVER environment variable..."
if [ -n "$PULSE_SERVER" ]; then
    echo -e "${GREEN}✅ PULSE_SERVER is set to: $PULSE_SERVER${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ PULSE_SERVER environment variable not set${NC}"
    echo "   Setting PULSE_SERVER=host.docker.internal for this session"
    export PULSE_SERVER=host.docker.internal
    ((TESTS_FAILED++))
fi

echo ""

# 3. Check PulseAudio utilities installation
echo "3. Checking PulseAudio utilities..."
REQUIRED_TOOLS=("pactl" "paplay" "speaker-test")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo -e "   ${GREEN}✅ $tool is installed${NC}"
    else
        echo -e "   ${RED}❌ $tool is not installed${NC}"
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
    ((TESTS_PASSED++))
else
    echo -e "${RED}Missing tools: ${MISSING_TOOLS[*]}${NC}"
    echo "   Install with: apt-get update && apt-get install -y pulseaudio-utils"
    ((TESTS_FAILED++))
fi

echo ""

# 4. Test network connectivity to host
echo "4. Testing network connectivity to host..."
PULSE_HOST="${PULSE_SERVER:-host.docker.internal}"
echo "   Target host: $PULSE_HOST"

# Try to resolve the hostname
if getent hosts "$PULSE_HOST" &>/dev/null || nslookup "$PULSE_HOST" &>/dev/null 2>&1; then
    echo -e "${GREEN}✅ Host $PULSE_HOST is resolvable${NC}"
    HOST_IP=$(getent hosts "$PULSE_HOST" | awk '{print $1}' | head -n1)
    if [ -n "$HOST_IP" ]; then
        echo "   Resolved to: $HOST_IP"
    fi
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ Cannot resolve $PULSE_HOST${NC}"
    ((TESTS_FAILED++))
fi

# Test basic connectivity
if ping -c 1 -W 2 "$PULSE_HOST" &>/dev/null; then
    echo -e "${GREEN}✅ Can ping $PULSE_HOST${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠️  Cannot ping $PULSE_HOST (this might be normal)${NC}"
fi

echo ""

# 5. Test PulseAudio connection
echo "5. Testing PulseAudio server connection..."
if pactl -s "$PULSE_HOST" info &>/dev/null; then
    echo -e "${GREEN}✅ Successfully connected to PulseAudio server${NC}"
    echo "   Server info:"
    pactl -s "$PULSE_HOST" info | grep -E "Server String|Server Name|Server Version" | sed 's/^/   /'
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ Failed to connect to PulseAudio server at $PULSE_HOST${NC}"
    echo "   Trying with verbose output..."
    PULSE_LOG=99 pactl -s "$PULSE_HOST" info 2>&1 | tail -n 10 | sed 's/^/   /'
    ((TESTS_FAILED++))
fi

echo ""

# 6. Check PulseAudio cookie/auth
echo "6. Checking PulseAudio authentication..."
PULSE_COOKIE="$HOME/.config/pulse/cookie"
if [ -f "$PULSE_COOKIE" ]; then
    echo -e "${GREEN}✅ PulseAudio cookie found${NC}"
    echo "   Location: $PULSE_COOKIE"
    echo "   Size: $(stat -c%s "$PULSE_COOKIE" 2>/dev/null || stat -f%z "$PULSE_COOKIE" 2>/dev/null) bytes"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠️  PulseAudio cookie not found${NC}"
    echo "   Expected at: $PULSE_COOKIE"
    echo "   This might cause authentication issues"
fi

echo ""

# 7. List audio outputs (sinks)
echo "7. Checking available audio outputs..."
SINKS=$(pactl -s "$PULSE_HOST" list sinks short 2>/dev/null)
if [ -n "$SINKS" ]; then
    echo -e "${GREEN}✅ Audio output devices found:${NC}"
    echo "$SINKS" | sed 's/^/   /'
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ No audio output devices found${NC}"
    ((TESTS_FAILED++))
fi

echo ""

# 8. Test audio tools
echo "8. Testing audio playback tools..."

# Check for test sounds
TEST_SOUNDS=(
    "/usr/share/sounds/alsa/Front_Center.wav"
    "/usr/share/sounds/alsa/Noise.wav"
    "/usr/share/sounds/sound-icons/trumpet-12.wav"
)

FOUND_SOUND=""
for sound in "${TEST_SOUNDS[@]}"; do
    if [ -f "$sound" ]; then
        FOUND_SOUND="$sound"
        break
    fi
done

if [ -n "$FOUND_SOUND" ]; then
    echo "   Found test sound: $FOUND_SOUND"
    
    # Test with paplay
    echo -n "   Testing paplay... "
    if paplay -s "$PULSE_HOST" "$FOUND_SOUND" 2>/dev/null; then
        echo -e "${GREEN}✅ Success${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Failed${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠️  No test sound files found${NC}"
    echo "   Testing with speaker-test instead..."
    
    echo "   Running speaker-test (2 seconds)..."
    if timeout 2s speaker-test -c 2 -t wav 2>/dev/null; then
        echo -e "${GREEN}✅ Speaker test successful${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Speaker test failed${NC}"
        ((TESTS_FAILED++))
    fi
fi

echo ""

# 9. Check afplay wrapper
echo "9. Checking afplay wrapper..."
if command -v afplay &> /dev/null; then
    echo -e "${GREEN}✅ afplay command is available${NC}"
    echo "   Location: $(which afplay)"
    
    if [ -n "$FOUND_SOUND" ]; then
        echo -n "   Testing afplay... "
        if afplay "$FOUND_SOUND" 2>/dev/null; then
            echo -e "${GREEN}✅ Success${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}❌ Failed${NC}"
            ((TESTS_FAILED++))
        fi
    fi
else
    echo -e "${YELLOW}⚠️  afplay wrapper not found${NC}"
    echo "   Expected at: /usr/local/bin/afplay"
fi

echo ""

# 10. Additional audio tools check
echo "10. Checking additional audio tools..."
AUDIO_TOOLS=("sox" "play" "mpg123" "ffplay")
for tool in "${AUDIO_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo -e "   ${GREEN}✅ $tool is installed${NC}"
    else
        echo -e "   ${YELLOW}○ $tool is not installed${NC}"
    fi
done

echo ""
echo "===================================="
echo "Test Summary:"
echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Audio passthrough is working.${NC}"
    echo ""
    echo "You can now play audio from the container using:"
    echo "  - paplay <audiofile>"
    echo "  - speaker-test -c 2 -t wav"
    echo "  - afplay <audiofile> (if wrapper is installed)"
else
    echo -e "${YELLOW}⚠️  Some tests failed. Troubleshooting tips:${NC}"
    echo ""
    echo "1. On the host Mac, ensure PulseAudio is running:"
    echo "   brew services restart pulseaudio"
    echo ""
    echo "2. Check if TCP module is loaded on host:"
    echo "   pactl list modules | grep tcp"
    echo ""
    echo "3. Ensure the container was started with proper settings:"
    echo "   - PULSE_SERVER=host.docker.internal"
    echo "   - Mount: ~/.config/pulse:/home/node/.config/pulse"
    echo ""
    echo "4. If authentication fails, try restarting both host and container"
fi