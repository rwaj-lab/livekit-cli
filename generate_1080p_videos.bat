@echo off
REM Script to generate 1080p test video files for LiveKit CLI load testing
REM Requires FFmpeg to be installed and in PATH

set OUTPUT_DIR=pkg\provider\resources
set DURATION=10
set FPS=30

echo Generating 1080p H.264 files...

REM Butterfly pattern - 1080p at 4000kbps
ffmpeg -f lavfi -i "testsrc2=size=1920x1080:rate=%FPS%,format=yuv420p" -t %DURATION% ^
  -c:v libx264 -preset fast -profile:v baseline -level 4.0 ^
  -b:v 4000k -maxrate 4000k -bufsize 8000k ^
  -x264-params "keyint=60:min-keyint=60:no-scenecut" ^
  -an "%OUTPUT_DIR%\butterfly_1080_4000.h264" -y

REM Cartoon pattern - 1080p at 3500kbps
ffmpeg -f lavfi -i "testsrc=size=1920x1080:rate=%FPS%,format=yuv420p" -t %DURATION% ^
  -c:v libx264 -preset fast -profile:v baseline -level 4.0 ^
  -b:v 3500k -maxrate 3500k -bufsize 7000k ^
  -x264-params "keyint=60:min-keyint=60:no-scenecut" ^
  -an "%OUTPUT_DIR%\cartoon_1080_3500.h264" -y

REM Circles pattern (portrait) - 1080p at 4000kbps
ffmpeg -f lavfi -i "testsrc2=size=1080x1920:rate=%FPS%,format=yuv420p" -t %DURATION% ^
  -c:v libx264 -preset fast -profile:v baseline -level 4.0 ^
  -b:v 4000k -maxrate 4000k -bufsize 8000k ^
  -x264-params "keyint=60:min-keyint=60:no-scenecut" ^
  -an "%OUTPUT_DIR%\circles_p1080_4000.h264" -y

echo Generating 1080p VP8 (IVF) files...

REM Crescent pattern - 1080p at 4000kbps
ffmpeg -f lavfi -i "smptebars=size=1920x1080:rate=%FPS%,format=yuv420p" -t %DURATION% ^
  -c:v libvpx -b:v 4000k -maxrate 4000k -bufsize 8000k ^
  -keyint_min 60 -g 60 -quality good -cpu-used 0 ^
  -an -f ivf "%OUTPUT_DIR%\crescent_1080_4000.ivf" -y

REM Neon pattern - 1080p at 4000kbps
ffmpeg -f lavfi -i "mandelbrot=size=1920x1080:rate=%FPS%,format=yuv420p" -t %DURATION% ^
  -c:v libvpx -b:v 4000k -maxrate 4000k -bufsize 8000k ^
  -keyint_min 60 -g 60 -quality good -cpu-used 0 ^
  -an -f ivf "%OUTPUT_DIR%\neon_1080_4000.ivf" -y

REM Tunnel pattern - 1080p at 4000kbps
ffmpeg -f lavfi -i "cellauto=size=1920x1080:rate=%FPS%:rule=110,format=yuv420p" -t %DURATION% ^
  -c:v libvpx -b:v 4000k -maxrate 4000k -bufsize 8000k ^
  -keyint_min 60 -g 60 -quality good -cpu-used 0 ^
  -an -f ivf "%OUTPUT_DIR%\tunnel_1080_4000.ivf" -y

echo 1080p video generation complete!
echo Generated files:
dir /b "%OUTPUT_DIR%\*1080*.h264" "%OUTPUT_DIR%\*1080*.ivf" 2>nul