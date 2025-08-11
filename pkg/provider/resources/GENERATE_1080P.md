# Generating 1080p Video Files

The LiveKit CLI load tester now supports 1080p resolution testing. The code is ready to use actual 1080p video files when they are available.

## Current Status

- The code supports 1080p specifications
- If 1080p files don't exist, it automatically falls back to using 720p files
- To enable true 1080p testing, you need to generate the 1080p video files

## Required 1080p Files

The following 1080p files need to be generated:

### H.264 Files
- `butterfly_1080_4000.h264` - 1920x1080 @ 4000kbps
- `cartoon_1080_3500.h264` - 1920x1080 @ 3500kbps  
- `circles_p1080_4000.h264` - 1080x1920 @ 4000kbps (portrait)

### VP8/IVF Files
- `crescent_1080_4000.ivf` - 1920x1080 @ 4000kbps
- `neon_1080_4000.ivf` - 1920x1080 @ 4000kbps
- `tunnel_1080_4000.ivf` - 1920x1080 @ 4000kbps

## How to Generate

### Prerequisites
- Install FFmpeg: https://ffmpeg.org/download.html
  - Windows: `winget install ffmpeg` or download from website
  - macOS: `brew install ffmpeg`
  - Linux: `apt-get install ffmpeg` or `yum install ffmpeg`

### Windows
Run the provided batch script:
```bash
cd C:\Users\rwaj\Documents\project\livekit-cli
generate_1080p_videos.bat
```

### Linux/macOS
Run the provided shell script:
```bash
cd /path/to/livekit-cli
chmod +x generate_1080p_videos.sh
./generate_1080p_videos.sh
```

## Manual Generation

If the scripts don't work, you can manually generate each file:

### H.264 Example (butterfly pattern):
```bash
ffmpeg -f lavfi -i "testsrc2=size=1920x1080:rate=30,format=yuv420p" -t 10 \
  -c:v libx264 -preset fast -profile:v baseline -level 4.0 \
  -b:v 4000k -maxrate 4000k -bufsize 8000k \
  -x264-params "keyint=60:min-keyint=60:no-scenecut" \
  -an "pkg/provider/resources/butterfly_1080_4000.h264" -y
```

### VP8/IVF Example (crescent pattern):
```bash
ffmpeg -f lavfi -i "smptebars=size=1920x1080:rate=30,format=yuv420p" -t 10 \
  -c:v libvpx -b:v 4000k -maxrate 4000k -bufsize 8000k \
  -keyint_min 60 -g 60 -quality good -cpu-used 0 \
  -an -f ivf "pkg/provider/resources/crescent_1080_4000.ivf" -y
```

## Verification

After generating the files, verify they exist:
```bash
ls -lh pkg/provider/resources/*1080*
```

The load tester will automatically detect and use the 1080p files once they're present.

## Usage

Once the files are generated:

```bash
# Use the very-high preset (1080p + 720p + 360p)
lk load-test --video-resolution very-high --video-publishers 5 --subscribers 100

# Or specify custom resolutions
lk load-test --video-resolution 1080,720,360 --video-publishers 5 --subscribers 100
```