# LiveKit CLI 1080p Load Testing Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [Features Added](#features-added)
3. [Installation Prerequisites](#installation-prerequisites)
4. [Building the Project](#building-the-project)
5. [Generating 1080p Video Files](#generating-1080p-video-files)
6. [Usage Examples](#usage-examples)
7. [Implementation Details](#implementation-details)
8. [Testing & Verification](#testing--verification)
9. [Troubleshooting](#troubleshooting)
10. [API Reference](#api-reference)

---

## Overview

This document describes the implementation of 1080p video resolution support for LiveKit CLI's load testing feature. The enhancement allows testing of LiveKit servers with Full HD (1920x1080) video streams, providing more realistic load testing scenarios for production environments.

### Key Capabilities
- **1080p Simulcast Support**: Test with 1080p + 720p + 360p simultaneous streams
- **Custom Resolution Combinations**: Specify exact resolution layers needed
- **Intelligent Fallback**: Automatically uses 720p files if 1080p files aren't available
- **Comprehensive Logging**: Track which video files and resolutions are being used

---

## Features Added

### 1. New Resolution Options

#### **Very-High Preset**
```bash
--video-resolution very-high
```
Publishes simulcast with three layers:
- 1920x1080 (1080p) at 4000 kbps
- 1280x720 (720p) at 2000 kbps  
- 640x360 (360p) at 600 kbps

#### **Custom Resolution Combinations**
```bash
--video-resolution "1080,720,360"  # All three layers
--video-resolution "1080,720"       # Just 1080p and 720p
--video-resolution "1080"           # Only 1080p
```

### 2. Existing Options (Still Supported)
- `high`: 720p + 360p + 180p (default)
- `medium`: 360p + 180p
- `low`: 180p only

### 3. Logging Enhancements
The system now logs:
- Which video files are being used (actual 1080p or fallback to 720p)
- Resolution layers being created
- Simulcast vs single-layer mode

---

## Installation Prerequisites

### 1. Go Programming Language

#### **Windows Installation**

**Option A: Using Winget (Recommended)**
```powershell
# Run as Administrator
winget install GoLang.Go

# Verify installation
go version
```

**Option B: Manual Installation**
1. Download from: https://go.dev/dl/
2. Run the installer (`go1.23.x.windows-amd64.msi`)
3. Restart your terminal
4. Verify: `go version`

### 2. Git and Git LFS

```powershell
# Install Git if not present
winget install Git.Git

# Install Git LFS for video resources
git lfs install
```

### 3. FFmpeg (For Generating 1080p Videos)

**Option A: Using Winget**
```powershell
winget install Gyan.FFmpeg
```

**Option B: Manual Installation**
1. Download from: https://www.gyan.dev/ffmpeg/builds/
2. Extract to `C:\ffmpeg`
3. Add `C:\ffmpeg\bin` to system PATH
4. Restart terminal
5. Verify: `ffmpeg -version`

---

## Building the Project

### 1. Clone or Update Repository

```bash
# If not already cloned
git clone https://github.com/livekit/livekit-cli
cd livekit-cli

# If already cloned, update
git pull
git lfs pull
```

### 2. Build the Binary

```bash
# Windows
go build -o lk.exe ./cmd/lk

# Or use Make (if available)
make cli
```

### 3. Verify Build

```bash
# Check version
.\lk.exe --version

# Check new options are present
.\lk.exe load-test --help | findstr "very-high"
```

---

## Generating 1080p Video Files

### Understanding the Video Files

The load tester uses pre-encoded video files in two formats:
- **H.264** files (`.h264`) - For H.264 codec testing
- **VP8/IVF** files (`.ivf`) - For VP8 codec testing

### Default Behavior (Without 1080p Files)

If 1080p video files don't exist, the system automatically:
1. Uses 720p video files for streaming
2. Reports 1080p dimensions (1920x1080) to the LiveKit server
3. Logs the fallback: `INFO: 1080p file not found, falling back to 720p`

### Generating Actual 1080p Files

#### **Automatic Generation (Recommended)**

```bash
# Navigate to project directory
cd C:\Users\rwaj\Documents\project\livekit-cli

# Run the generation script
.\generate_1080p_videos.bat
```

This creates 6 files in `pkg\provider\resources\`:
- `butterfly_1080_4000.h264` - Colorful test pattern
- `cartoon_1080_3500.h264` - Standard test pattern
- `circles_p1080_4000.h264` - Portrait mode circles
- `crescent_1080_4000.ivf` - SMPTE color bars (VP8)
- `neon_1080_4000.ivf` - Mandelbrot pattern (VP8)
- `tunnel_1080_4000.ivf` - Cellular automaton (VP8)

#### **Manual Generation**

If the script fails, generate files manually:

```bash
# H.264 Example
ffmpeg -f lavfi -i "testsrc2=size=1920x1080:rate=30,format=yuv420p" -t 10 \
  -c:v libx264 -preset fast -profile:v baseline -level 4.0 \
  -b:v 4000k -maxrate 4000k -bufsize 8000k \
  -x264-params "keyint=60:min-keyint=60:no-scenecut" \
  -an "pkg/provider/resources/butterfly_1080_4000.h264" -y

# VP8/IVF Example  
ffmpeg -f lavfi -i "smptebars=size=1920x1080:rate=30,format=yuv420p" -t 10 \
  -c:v libvpx -b:v 4000k -maxrate 4000k -bufsize 8000k \
  -keyint_min 60 -g 60 -quality good -cpu-used 0 \
  -an -f ivf "pkg/provider/resources/crescent_1080_4000.ivf" -y
```

### Verifying Files

```bash
# List generated files
dir pkg\provider\resources\*1080*

# Check file sizes (should be > 1MB each)
```

---

## Usage Examples

### LiveKit Server Setup

First, ensure you have a LiveKit server running:

```bash
# Using Docker
docker run -d --rm \
  -p 7880:7880 \
  -p 7881:7881 \
  -p 7882:7882/udp \
  -e LIVEKIT_KEYS="devkey: devsecret" \
  --name livekit-server \
  livekit/livekit-server \
  --dev \
  --node-ip=127.0.0.1
```

### Basic Load Tests

#### **1. Very-High Resolution Test**
```bash
.\lk.exe load-test \
  --video-resolution very-high \
  --video-publishers 2 \
  --subscribers 5 \
  --duration 30s \
  --api-key devkey \
  --api-secret devsecret \
  --url ws://localhost:7880
```

#### **2. Custom Resolution Combination**
```bash
# 1080p and 720p only
.\lk.exe load-test \
  --video-resolution "1080,720" \
  --video-publishers 3 \
  --subscribers 10 \
  --duration 1m \
  --api-key devkey \
  --api-secret devsecret \
  --url ws://localhost:7880
```

#### **3. Single 1080p Stream (No Simulcast)**
```bash
.\lk.exe load-test \
  --video-resolution "1080" \
  --no-simulcast \
  --video-publishers 1 \
  --subscribers 5 \
  --duration 30s \
  --api-key devkey \
  --api-secret devsecret \
  --url ws://localhost:7880
```

### Advanced Load Tests

#### **4. Mixed Publishers Test**
```bash
# 2 video publishers at 1080p + 3 audio publishers
.\lk.exe load-test \
  --video-resolution very-high \
  --video-publishers 2 \
  --audio-publishers 3 \
  --subscribers 20 \
  --duration 2m \
  --api-key devkey \
  --api-secret devsecret \
  --url ws://localhost:7880
```

#### **5. Performance Stress Test**
```bash
# High load with 1080p
.\lk.exe load-test \
  --video-resolution very-high \
  --video-publishers 5 \
  --subscribers 50 \
  --duration 5m \
  --num-per-second 2 \
  --layout 3x3 \
  --api-key devkey \
  --api-secret devsecret \
  --url ws://localhost:7880
```

#### **6. Codec-Specific Testing**
```bash
# H.264 only
.\lk.exe load-test \
  --video-resolution very-high \
  --video-codec h264 \
  --video-publishers 2 \
  --duration 30s \
  --api-key devkey \
  --api-secret devsecret \
  --url ws://localhost:7880

# VP8 only
.\lk.exe load-test \
  --video-resolution very-high \
  --video-codec vp8 \
  --video-publishers 2 \
  --duration 30s \
  --api-key devkey \
  --api-secret devsecret \
  --url ws://localhost:7880
```

### Using with LiveKit Cloud

```bash
# Configure project
lk cloud auth
lk project add --api-key <your-key> --api-secret <your-secret> my-project

# Run test (credentials automatically loaded)
.\lk.exe load-test \
  --video-resolution very-high \
  --video-publishers 2 \
  --duration 30s
```

---

## Implementation Details

### Modified Files

1. **`pkg/provider/embeds.go`**
   - Added `createSpecsWithHD()` function for 1080p specifications
   - Modified `Name()` method to handle 1080p file detection and fallback
   - Added `getSpecsForResolution()` for resolution preset handling
   - Added `createCustomSpecs()` for custom resolution combinations
   - Enhanced logging throughout

2. **`cmd/lk/perf.go`**
   - Updated help text for `--video-resolution` flag
   - Added documentation for new options

3. **`pkg/loadtester/loadtester.go`**
   - Added constants for 1080p dimensions (`veryHighWidth`, `veryHighHeight`)

### Video Specifications

#### 1080p Specs Added
```go
{
    prefix: "butterfly",
    codec:  "h264",
    height: 1080,
    width:  1920,
    kbps:   4000,
    fps:    30,
}
```

#### Resolution Mappings
- `very-high`: [360p, 720p, 1080p]
- `high`: [180p, 360p, 720p]
- `medium`: [180p, 360p]
- `low`: [180p]

### Fallback Mechanism

The system checks for 1080p files in this order:
1. Try to open the 1080p file (e.g., `butterfly_1080_4000.h264`)
2. If not found, use corresponding 720p file (e.g., `butterfly_720_2000.h264`)
3. Report 1080p dimensions to LiveKit server regardless
4. Log the fallback for debugging

---

## Testing & Verification

### 1. Verify Installation

```bash
# Check Go
go version

# Check FFmpeg
ffmpeg -version

# Check LiveKit CLI
.\lk.exe --version
```

### 2. Test Logging

Run the provided test script:
```bash
.\test_logging.bat
```

Expected output patterns:
```
INFO: Creating very-high resolution looper
INFO: Simulcast mode - using 3 layers: 640x360, 1280x720, 1920x1080
INFO: Using actual 1080p file: resources/butterfly_1080_4000.h264
# OR
INFO: 1080p file not found (resources/butterfly_1080_4000.h264), falling back to 720p file
```

### 3. Monitor Server Performance

During load tests, monitor:
- **CPU Usage**: Should scale with number of subscribers
- **Memory Usage**: Increases with resolution and participant count
- **Network Bandwidth**: 
  - 1080p: ~4 Mbps per publisher
  - 720p: ~2 Mbps per publisher
  - 360p: ~600 Kbps per publisher

### 4. Verify with LiveKit Meet

```bash
# Generate a token to join the test room
.\lk.exe token create \
  --join \
  --room testroom123 \
  --identity observer \
  --api-key devkey \
  --api-secret devsecret

# Open Meet and paste the token
# URL: https://meet.livekit.io
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. "go: command not found"
**Solution**: Install Go and restart terminal
```powershell
winget install GoLang.Go
# Close and reopen terminal
```

#### 2. "ffmpeg: command not found"
**Solution**: Install FFmpeg or use full path
```powershell
winget install Gyan.FFmpeg
# OR specify full path in script
C:\ffmpeg\bin\ffmpeg.exe ...
```

#### 3. "unauthorized: invalid token"
**Solution**: Check API credentials match server configuration
```bash
# For local development
--api-key devkey --api-secret devsecret

# Check server logs
docker logs livekit-server
```

#### 4. "No such file or directory" when generating videos
**Solution**: Ensure resources directory exists
```bash
mkdir -p pkg\provider\resources
```

#### 5. Build errors
**Solution**: Update dependencies
```bash
go mod download
go mod tidy
```

#### 6. Video files not detected
**Solution**: Check file names and permissions
```bash
# List files
dir pkg\provider\resources\*.h264
dir pkg\provider\resources\*.ivf

# Check Git LFS
git lfs pull
```

### Performance Issues

#### High CPU Usage
- Reduce number of publishers
- Use lower resolution (`high` instead of `very-high`)
- Disable simulcast with `--no-simulcast`

#### Network Bottlenecks
- Reduce `--num-per-second` to slow connection rate
- Use fewer subscribers
- Test with local server first

#### Memory Issues
- Limit concurrent tests
- Use shorter `--duration`
- Monitor with Task Manager or Performance Monitor

---

## API Reference

### Command Line Flags

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--video-resolution` | string | "high" | Resolution quality preset or custom combination |
| `--video-publishers` | int | 0 | Number of video publishing participants |
| `--audio-publishers` | int | 0 | Number of audio publishing participants |
| `--subscribers` | int | 0 | Number of subscribing participants |
| `--duration` | duration | unlimited | Test duration (e.g., "30s", "5m", "1h") |
| `--no-simulcast` | bool | false | Disable simulcast, use single layer |
| `--video-codec` | string | both | Codec selection: "h264", "vp8", or both |
| `--num-per-second` | float | 5 | Rate of participant connections |
| `--layout` | string | "speaker" | Layout simulation: "speaker", "3x3", "4x4", "5x5" |

### Resolution Options

| Preset | Layers | Resolutions | Bitrates |
|--------|--------|-------------|----------|
| `very-high` | 3 | 1080p, 720p, 360p | 4000k, 2000k, 600k |
| `high` | 3 | 720p, 360p, 180p | 2000k, 600k, 150k |
| `medium` | 2 | 360p, 180p | 600k, 150k |
| `low` | 1 | 180p | 150k |

### Custom Resolution Format

```
"<resolution1>[,<resolution2>][,<resolution3>]"
```

Valid resolution values:
- `1080` or `1080p` - 1920x1080
- `720` or `720p` - 1280x720
- `360` or `360p` - 640x360
- `180` or `180p` - 320x180

Examples:
- `"1080,720,360"` - Three layers
- `"1080,360"` - Two layers (skip 720p)
- `"1080"` - Single 1080p layer

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `LIVEKIT_URL` | Default server URL | `ws://localhost:7880` |
| `LIVEKIT_API_KEY` | Default API key | `devkey` |
| `LIVEKIT_API_SECRET` | Default API secret | `devsecret` |

---

## Additional Resources

### Documentation
- [LiveKit Documentation](https://docs.livekit.io)
- [LiveKit CLI GitHub](https://github.com/livekit/livekit-cli)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)

### Support Files Created
- `generate_1080p_videos.bat` - Windows batch script for video generation
- `generate_1080p_videos.sh` - Linux/Mac script for video generation
- `test_logging.bat` - Test script to verify logging
- `GENERATE_1080P.md` - Quick guide for video generation
- `TEST_PLAN.md` - Comprehensive testing procedures

### Community
- [LiveKit Community Slack](https://livekit.io/join-slack)
- [GitHub Issues](https://github.com/livekit/livekit-cli/issues)

---

## Summary

The 1080p implementation for LiveKit CLI load testing provides:

1. **Flexibility**: Support for both preset and custom resolution combinations
2. **Compatibility**: Backward compatible with existing scripts and configurations
3. **Intelligence**: Automatic fallback when 1080p files aren't available
4. **Visibility**: Comprehensive logging for debugging and monitoring
5. **Performance**: Optimized for high-resolution load testing scenarios

This enhancement enables more realistic load testing of LiveKit deployments, particularly for applications requiring Full HD video quality.

---

*Document Version: 1.0*  
*Last Updated: January 2025*  
*Implementation by: LiveKit CLI Contributors*