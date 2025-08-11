# LiveKit CLI 1080p Load Testing - Test Plan

## Prerequisites

### 1. Install Go (if not installed)
```bash
# Windows - Using winget
winget install GoLang.Go

# Or download from: https://go.dev/dl/
```

### 2. Build the Project
```bash
cd C:\Users\rwaj\Documents\project\livekit-cli

# Build for Windows
go build -o lk.exe ./cmd/lk

# Or use Make (if make is installed)
make cli
```

## Test Cases

### Test 1: Verify Help Text
```bash
# Check that the new resolution options are documented
.\lk.exe load-test --help | findstr "video-resolution"

# Expected output should include:
# --video-resolution  Resolution QUALITY of video to publish. Options: "very-high" (1080p+720p+360p), "high" (720p+360p+180p), "medium" (360p+180p), "low" (180p), or custom like "1080,720,360" or "720,360"
```

### Test 2: Test "very-high" Resolution
```bash
# Test with very-high resolution (1080p + 720p + 360p)
.\lk.exe load-test --url <your-livekit-url> --api-key <key> --api-secret <secret> --room test-1080p --video-resolution very-high --video-publishers 2 --subscribers 2 --duration 30s

# Monitor the output for:
# - "publishing simulcast video track" messages
# - Track resolutions being published
# - No errors related to video resolution
```

### Test 3: Test Custom Resolution Combinations
```bash
# Test 1080p + 720p
.\lk.exe load-test --url <your-livekit-url> --api-key <key> --api-secret <secret> --room test-custom-1 --video-resolution "1080,720" --video-publishers 1 --subscribers 1 --duration 30s

# Test 1080p + 360p
.\lk.exe load-test --url <your-livekit-url> --api-key <key> --api-secret <secret> --room test-custom-2 --video-resolution "1080,360" --video-publishers 1 --subscribers 1 --duration 30s

# Test just 1080p
.\lk.exe load-test --url <your-livekit-url> --api-key <key> --api-secret <secret> --room test-custom-3 --video-resolution "1080" --video-publishers 1 --subscribers 1 --duration 30s
```

### Test 4: Verify Backward Compatibility
```bash
# Test that existing resolution options still work
.\lk.exe load-test --url <your-livekit-url> --api-key <key> --api-secret <secret> --room test-high --video-resolution high --video-publishers 1 --subscribers 1 --duration 30s

.\lk.exe load-test --url <your-livekit-url> --api-key <key> --api-secret <secret> --room test-medium --video-resolution medium --video-publishers 1 --subscribers 1 --duration 30s

.\lk.exe load-test --url <your-livekit-url> --api-key <key> --api-secret <secret> --room test-low --video-resolution low --video-publishers 1 --subscribers 1 --duration 30s
```

### Test 5: Performance Test with Multiple Publishers
```bash
# Test with multiple 1080p publishers to verify performance
.\lk.exe load-test --url <your-livekit-url> --api-key <key> --api-secret <secret> --room test-perf --video-resolution very-high --video-publishers 5 --subscribers 10 --duration 1m
```

## Expected Behaviors

1. **Fallback Mechanism**: Since actual 1080p video files don't exist yet, the system should:
   - Use 720p files but report 1080p dimensions (1920x1080)
   - Not show any file not found errors
   - Successfully publish tracks

2. **Simulcast Layers**: When using "very-high", you should see:
   - 3 simulcast layers being published
   - Resolutions: 360p, 720p, and 1080p (reported dimensions)

3. **Custom Resolutions**: Should accept any valid combination of:
   - "1080", "1080p", "720", "720p", "360", "360p", "180", "180p"
   - Invalid resolutions should be ignored

## Monitoring During Tests

### Check LiveKit Server Logs
Monitor the LiveKit server logs for:
- Track subscription events
- Video layer switching
- Bandwidth allocation for 1080p streams

### Check Client Output
The load test client should show:
- Number of tracks published/subscribed
- Bitrate information
- Packet loss statistics
- No errors related to video encoding/decoding

## Troubleshooting

### If build fails:
1. Ensure Go 1.24+ is installed: `go version`
2. Check all dependencies: `go mod download`
3. Try verbose build: `go build -v -o lk.exe ./cmd/lk`

### If tests fail:
1. Verify LiveKit server is running and accessible
2. Check API credentials are correct
3. Ensure network connectivity
4. Check if port 7880 (default) is open

### To generate actual 1080p files (optional):
1. Install FFmpeg: `winget install ffmpeg`
2. Run: `.\generate_1080p_videos.bat`
3. Verify files created in `pkg\provider\resources\`

## Success Criteria

✅ Build completes without errors
✅ Help text shows new resolution options
✅ "very-high" resolution works without errors
✅ Custom resolution combinations work
✅ Backward compatibility maintained
✅ No performance degradation
✅ Proper fallback to 720p files when 1080p not available