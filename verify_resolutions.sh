#!/bin/bash

# LiveKit CLI Video Resolution Verification Script
# Works on Windows (Git Bash/WSL), macOS, and Linux

echo "========================================"
echo "LiveKit CLI Video Resolution Verification"
echo "========================================"
echo ""

# Detect OS and set binary name
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    LK_BIN="./lk.exe"
    OS_TYPE="Windows"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    LK_BIN="./lk"
    OS_TYPE="macOS"
else
    LK_BIN="./lk"
    OS_TYPE="Linux"
fi

echo "Detected OS: $OS_TYPE"
echo "Using binary: $LK_BIN"
echo ""

# Check if binary exists
if [ ! -f "$LK_BIN" ]; then
    echo "Error: $LK_BIN not found. Please build the project first:"
    echo "  go build -o $LK_BIN ./cmd/lk"
    exit 1
fi

# Check LiveKit server connection
echo "Checking LiveKit server..."
if ! $LK_BIN load-test --video-publishers 0 --duration 1s --api-key devkey --api-secret devsecret --url ws://localhost:7880 2>&1 | grep -q "Finished connecting"; then
    echo "Warning: LiveKit server may not be running on ws://localhost:7880"
    echo "Start it with: docker run -d --rm -p 7880:7880 -p 7881:7881 -p 7882:7882/udp -e LIVEKIT_KEYS=\"devkey: devsecret\" --name livekit-server livekit/livekit-server --dev --node-ip=127.0.0.1"
    echo ""
fi

# Define test cases
declare -a resolutions=("very-high" "high" "medium" "low" "1080,720,360" "1080,720" "1080" "720,360" "360")
declare -a descriptions=(
    "1080p+720p+360p simulcast"
    "720p+360p+180p simulcast"
    "360p+180p simulcast"
    "180p single layer"
    "Custom 1080p+720p+360p"
    "Custom 1080p+720p"
    "Custom 1080p only"
    "Custom 720p+360p"
    "Custom 360p only"
)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test resolution
test_resolution() {
    local resolution=$1
    local description=$2
    local test_num=$3
    local total=$4
    
    echo -e "${YELLOW}[$test_num/$total]${NC} Testing: --video-resolution $resolution"
    echo "         Description: $description"
    
    # Run the test
    output=$($LK_BIN load-test --video-resolution "$resolution" \
        --video-publishers 1 --duration 2s \
        --api-key devkey --api-secret devsecret \
        --url ws://localhost:7880 2>&1)
    
    # Check if test ran successfully
    if echo "$output" | grep -q "INFO:"; then
        echo -e "         ${GREEN}✓${NC} Resolution mode working"
        
        # Check for resolution-specific patterns
        if [[ "$resolution" == *"1080"* ]] || [[ "$resolution" == "very-high" ]]; then
            if echo "$output" | grep -q "Using actual 1080p file"; then
                echo -e "         ${GREEN}✓${NC} Using actual 1080p files"
            elif echo "$output" | grep -q "falling back to 720p"; then
                echo -e "         ${YELLOW}⚠${NC} Falling back to 720p (1080p files missing)"
            fi
        fi
        
        # Extract and display layer information
        if echo "$output" | grep -q "Simulcast mode"; then
            layers=$(echo "$output" | grep "Simulcast mode" | sed 's/.*using [0-9] layers: //')
            echo "         Layers: $layers"
        elif echo "$output" | grep -q "Non-simulcast mode"; then
            layer=$(echo "$output" | grep "Non-simulcast" | sed 's/.*single layer at //')
            echo "         Single layer: $layer"
        fi
    else
        echo -e "         ${RED}✗${NC} Failed to test resolution"
    fi
    
    echo ""
}

# Run resolution tests
echo "Starting Resolution Tests"
echo "========================="
echo ""

total=${#resolutions[@]}
for i in "${!resolutions[@]}"; do
    test_resolution "${resolutions[$i]}" "${descriptions[$i]}" $((i+1)) $total
done

# Test --no-simulcast flag
echo "Testing --no-simulcast Flag"
echo "============================"
echo ""

echo -e "${YELLOW}[Special Test 1]${NC} Testing: --video-resolution very-high --no-simulcast"
output=$($LK_BIN load-test --video-resolution "very-high" --no-simulcast \
    --video-publishers 1 --duration 2s \
    --api-key devkey --api-secret devsecret \
    --url ws://localhost:7880 2>&1)

if echo "$output" | grep -q "Non-simulcast mode"; then
    echo -e "         ${GREEN}✓${NC} No-simulcast mode working (sends only highest resolution)"
else
    echo -e "         ${RED}✗${NC} No-simulcast test failed"
fi
echo ""

# Check for 1080p video files
echo "Checking 1080p Video Files"
echo "=========================="
echo ""

h264_count=0
ivf_count=0

for file in butterfly_1080_4000.h264 cartoon_1080_3500.h264 circles_p1080_4000.h264; do
    if [ -f "pkg/provider/resources/$file" ]; then
        size=$(du -h "pkg/provider/resources/$file" 2>/dev/null | cut -f1)
        echo -e "${GREEN}✓${NC} $file ($size)"
        ((h264_count++))
    else
        echo -e "${RED}✗${NC} $file - MISSING"
    fi
done

for file in crescent_1080_4000.ivf neon_1080_4000.ivf tunnel_1080_4000.ivf; do
    if [ -f "pkg/provider/resources/$file" ]; then
        size=$(du -h "pkg/provider/resources/$file" 2>/dev/null | cut -f1)
        echo -e "${GREEN}✓${NC} $file ($size)"
        ((ivf_count++))
    else
        echo -e "${RED}✗${NC} $file - MISSING"
    fi
done

echo ""
echo "Summary"
echo "======="
echo "H.264 files: $h264_count/3"
echo "VP8/IVF files: $ivf_count/3"

if [ $h264_count -eq 3 ] && [ $ivf_count -eq 3 ]; then
    echo -e "${GREEN}✓ All 1080p files present - Full 1080p support enabled${NC}"
elif [ $h264_count -gt 0 ] || [ $ivf_count -gt 0 ]; then
    echo -e "${YELLOW}⚠ Some 1080p files missing - Partial 1080p support${NC}"
    echo "  Run generate_1080p.sh to create missing files"
else
    echo -e "${YELLOW}⚠ No 1080p files found - Using 720p fallback${NC}"
    echo "  Run generate_1080p.sh to enable full 1080p support"
fi

echo ""
echo "Verification complete!"