#!/bin/bash

# Script to generate 1080p test video files for LiveKit CLI load testing
# Requires FFmpeg to be installed

OUTPUT_DIR="pkg/provider/resources"
DURATION=10  # 10 seconds of video
FPS=30       # 30 fps for 1080p

# Color patterns for different video types
BUTTERFLY_PATTERN="testsrc2=size=1920x1080:rate=$FPS,format=yuv420p"
CARTOON_PATTERN="testsrc=size=1920x1080:rate=$FPS,format=yuv420p"
CRESCENT_PATTERN="smptebars=size=1920x1080:rate=$FPS,format=yuv420p"
NEON_PATTERN="mandelbrot=size=1920x1080:rate=$FPS,format=yuv420p"
TUNNEL_PATTERN="cellauto=size=1920x1080:rate=$FPS:rule=110,format=yuv420p"
CIRCLES_PATTERN="testsrc2=size=1080x1920:rate=$FPS,format=yuv420p"  # Portrait mode

echo "Generating 1080p H.264 files..."

# Generate H.264 files
# Butterfly pattern - 1080p at 4000kbps
ffmpeg -f lavfi -i "$BUTTERFLY_PATTERN" -t $DURATION \
  -c:v libx264 -preset fast -profile:v baseline -level 4.0 \
  -b:v 4000k -maxrate 4000k -bufsize 8000k \
  -x264-params "keyint=60:min-keyint=60:no-scenecut" \
  -an "$OUTPUT_DIR/butterfly_1080_4000.h264" -y

# Cartoon pattern - 1080p at 3500kbps
ffmpeg -f lavfi -i "$CARTOON_PATTERN" -t $DURATION \
  -c:v libx264 -preset fast -profile:v baseline -level 4.0 \
  -b:v 3500k -maxrate 3500k -bufsize 7000k \
  -x264-params "keyint=60:min-keyint=60:no-scenecut" \
  -an "$OUTPUT_DIR/cartoon_1080_3500.h264" -y

# Circles pattern (portrait) - 1080p at 4000kbps
ffmpeg -f lavfi -i "$CIRCLES_PATTERN" -t $DURATION \
  -c:v libx264 -preset fast -profile:v baseline -level 4.0 \
  -b:v 4000k -maxrate 4000k -bufsize 8000k \
  -x264-params "keyint=60:min-keyint=60:no-scenecut" \
  -an "$OUTPUT_DIR/circles_p1080_4000.h264" -y

echo "Generating 1080p VP8 (IVF) files..."

# Generate VP8 IVF files
# Crescent pattern - 1080p at 4000kbps
ffmpeg -f lavfi -i "$CRESCENT_PATTERN" -t $DURATION \
  -c:v libvpx -b:v 4000k -maxrate 4000k -bufsize 8000k \
  -keyint_min 60 -g 60 -quality good -cpu-used 0 \
  -an -f ivf "$OUTPUT_DIR/crescent_1080_4000.ivf" -y

# Neon pattern - 1080p at 4000kbps
ffmpeg -f lavfi -i "$NEON_PATTERN" -t $DURATION \
  -c:v libvpx -b:v 4000k -maxrate 4000k -bufsize 8000k \
  -keyint_min 60 -g 60 -quality good -cpu-used 0 \
  -an -f ivf "$OUTPUT_DIR/neon_1080_4000.ivf" -y

# Tunnel pattern - 1080p at 4000kbps
ffmpeg -f lavfi -i "$TUNNEL_PATTERN" -t $DURATION \
  -c:v libvpx -b:v 4000k -maxrate 4000k -bufsize 8000k \
  -keyint_min 60 -g 60 -quality good -cpu-used 0 \
  -an -f ivf "$OUTPUT_DIR/tunnel_1080_4000.ivf" -y

echo "1080p video generation complete!"
echo "Generated files:"
ls -lh "$OUTPUT_DIR"/*1080*.h264 "$OUTPUT_DIR"/*1080*.ivf 2>/dev/null