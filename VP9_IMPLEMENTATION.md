# VP9 Codec Support Implementation

## Overview
This document describes the VP9 codec support implementation for livekit-cli load testing functionality.

## Problem Fixed
The original issue was a panic when using `--video-codec vp9` with `--video-resolution very-high`:
- VP9 codec was not supported in the codebase
- Attempting to use VP9 resulted in an empty array access panic at `pkg/provider/embeds.go:201`

## Implementation Steps

### 1. Generate VP9 Test Video Files
VP9-encoded test videos in IVF container format were generated using the provided script:

```powershell
# Run this to generate VP9 test files
powershell -ExecutionPolicy Bypass -File generate_vp9_videos_fast.ps1
```

This creates gradient-pattern VP9 videos at multiple resolutions:
- `gradient_180_150.ivf` (180p)
- `gradient_360_600.ivf` (360p) 
- `gradient_720_2000.ivf` (720p)
- `gradient_1080_4000.ivf` (1080p)

### 2. Files Modified/Created

#### Created: `pkg/provider/vp9looper.go`
- New VP9VideoLooper implementation
- Handles VP9 codec negotiation with WebRTC
- Reads VP9 IVF files and provides media samples

#### Modified: `pkg/provider/embeds.go`
- Added `vp9Codec = "vp9"` constant
- Fixed `Name()` method to use `.ivf` extension for VP9 files
- Added VP9 video specs using gradient pattern
- Added VP9VideoLooper creation in `CreateVideoLoopers()`
- Removed the problematic VP8 fallback logic

#### Created: Helper Scripts
- `generate_vp9_videos_fast.ps1` - Generates VP9 test videos quickly
- `generate_vp9_videos.ps1` - Full quality VP9 video generation (slower)

## Building and Testing

### Prerequisites
Ensure ffmpeg is installed:
```powershell
winget install Gyan.FFmpeg
```

### Build Steps
1. Generate VP9 test files (if not already present):
```powershell
powershell -ExecutionPolicy Bypass -File generate_vp9_videos_fast.ps1
```

2. Build the CLI:
```bash
go build -o lk.exe ./cmd/lk
```

### Testing VP9 Support
Test VP9 codec with load testing:
```bash
# Test with VP9 codec and very-high resolution
./lk.exe load-test --publishers 1 --subscribers 5 \
  --video-resolution very-high --duration 30s \
  --video-codec vp9 --no-simulcast \
  --api-key YOUR_API_KEY --api-secret YOUR_API_SECRET \
  --url YOUR_LIVEKIT_URL
```

## Verification
The implementation correctly:
1. Supports VP9 codec without panicking
2. Loads proper VP9-encoded IVF files
3. Creates VP9VideoLooper instances with correct codec capabilities
4. Handles all resolution levels including very-high (1080p)

## Notes
- VP9 uses IVF container format (same as VP8)
- The gradient pattern is used for VP9 test videos to distinguish from VP8 patterns
- VP9 codec capability includes `profile-id=0` in SDPFmtpLine for proper WebRTC negotiation