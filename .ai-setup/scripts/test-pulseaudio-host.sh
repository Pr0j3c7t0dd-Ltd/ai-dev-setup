#!/bin/bash

# Test PulseAudio on Host Mac
# This script checks if PulseAudio is properly configured and running on the host

echo "🔊 PulseAudio Host Test Script"
echo "=============================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
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

# 1. Check if PulseAudio is installed
echo "1. Checking PulseAudio installation..."
if command -v pulseaudio &> /dev/null; then
    echo -e "${GREEN}✅ PulseAudio is installed${NC}"
    echo "   Location: $(which pulseaudio)"
    echo "   Version: $(pulseaudio --version | head -n1)"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ PulseAudio is not installed${NC}"
    echo "   Install with: brew install pulseaudio"
    ((TESTS_FAILED++))
    exit 1
fi

echo ""

# 2. Check if PulseAudio service is registered
echo "2. Checking PulseAudio service..."
if brew services list | grep -q "pulseaudio"; then
    SERVICE_STATUS=$(brew services list | grep pulseaudio)
    if echo "$SERVICE_STATUS" | grep -q "started"; then
        echo -e "${GREEN}✅ PulseAudio service is running${NC}"
        echo "   Status: $SERVICE_STATUS"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  PulseAudio service is not started${NC}"
        echo "   Status: $SERVICE_STATUS"
        echo "   Start with: brew services start pulseaudio"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}❌ PulseAudio service not found in brew services${NC}"
    ((TESTS_FAILED++))
fi

echo ""

# 3. Check if PulseAudio daemon is running
echo "3. Checking PulseAudio daemon..."
if pulseaudio --check; then
    echo -e "${GREEN}✅ PulseAudio daemon is running${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ PulseAudio daemon is not running${NC}"
    echo "   Try: pulseaudio --start"
    ((TESTS_FAILED++))
fi

echo ""

# 4. Check PulseAudio server info
echo "4. Getting PulseAudio server info..."
if pactl info &>/dev/null; then
    echo -e "${GREEN}✅ Successfully connected to PulseAudio server${NC}"
    echo "   Server info:"
    pactl info | grep -E "Server String|Server Name|Server Version|Default Sink|Default Source" | sed 's/^/   /'
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ Failed to connect to PulseAudio server${NC}"
    ((TESTS_FAILED++))
fi

echo ""

# 5. Check TCP module for network audio
echo "5. Checking network audio support (TCP module)..."
TCP_MODULE=$(pactl list modules short 2>/dev/null | grep "module-native-protocol-tcp")
if [ -n "$TCP_MODULE" ]; then
    echo -e "${GREEN}✅ TCP module is loaded for network audio${NC}"
    echo "   Module: $TCP_MODULE"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠️  TCP module not loaded${NC}"
    echo "   Loading TCP module..."
    if pactl load-module module-native-protocol-tcp &>/dev/null; then
        echo -e "${GREEN}✅ TCP module loaded successfully${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Failed to load TCP module${NC}"
        ((TESTS_FAILED++))
    fi
fi

echo ""

# 6. Check PulseAudio configuration
echo "6. Checking PulseAudio configuration..."
CONFIG_FILE="$HOME/.config/pulse/default.pa"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✅ PulseAudio config file exists${NC}"
    echo "   Location: $CONFIG_FILE"
    
    if grep -q "module-native-protocol-tcp" "$CONFIG_FILE"; then
        echo -e "${GREEN}✅ TCP module configured in default.pa${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  TCP module not found in default.pa${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠️  PulseAudio config file not found${NC}"
    echo "   Expected at: $CONFIG_FILE"
    ((TESTS_FAILED++))
fi

echo ""

# 7. List audio sinks
echo "7. Checking audio output devices (sinks)..."
SINKS=$(pactl list sinks short 2>/dev/null)
if [ -n "$SINKS" ]; then
    echo -e "${GREEN}✅ Audio output devices found${NC}"
    echo "$SINKS" | sed 's/^/   /'
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ No audio output devices found${NC}"
    ((TESTS_FAILED++))
fi

echo ""

# 8. Test audio playback
echo "8. Testing audio playback..."
TEST_SOUND="/System/Library/Sounds/Ping.aiff"
if [ -f "$TEST_SOUND" ]; then
    echo "   Playing test sound: $TEST_SOUND"
    if paplay "$TEST_SOUND" 2>/dev/null; then
        echo -e "${GREEN}✅ Audio playback successful${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Audio playback failed${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠️  Test sound file not found${NC}"
fi

echo ""

# 9. Check network accessibility
echo "9. Checking network accessibility..."
# Get the IP address that Docker will use
if command -v ipconfig &>/dev/null; then
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
    if [ -n "$LOCAL_IP" ]; then
        echo -e "${GREEN}✅ Local IP address: $LOCAL_IP${NC}"
        echo "   Docker containers will connect via: host.docker.internal"
        ((TESTS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  Could not determine local IP address${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  ipconfig command not found${NC}"
fi

# Check if PulseAudio is listening on TCP
if lsof -i :4713 &>/dev/null || netstat -an | grep -q "4713.*LISTEN" &>/dev/null; then
    echo -e "${GREEN}✅ PulseAudio is listening on port 4713 (TCP)${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠️  PulseAudio may not be listening on TCP port 4713${NC}"
    echo "   This is normal if using Unix socket authentication"
fi

echo ""
echo "=============================="
echo "Test Summary:"
echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! PulseAudio is ready for devcontainer use.${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed. Please address the issues above.${NC}"
fi

echo ""
echo "Next steps:"
echo "  1. If any tests failed, fix the issues and run this script again"
echo "  2. Run the devcontainer test script from inside your container"
echo "  3. If using VS Code, rebuild your devcontainer after fixes"