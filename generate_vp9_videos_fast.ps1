# Generate VP9 video files for testing (faster version)
# This script generates VP9-encoded IVF files at various resolutions

$ffmpegPath = "C:\Users\rwaj\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-7.1.1-full_build\bin\ffmpeg.exe"

# Check if ffmpeg exists
if (-not (Test-Path $ffmpegPath)) {
    Write-Host "Error: ffmpeg not found at $ffmpegPath" -ForegroundColor Red
    Write-Host "Please install ffmpeg using: winget install Gyan.FFmpeg" -ForegroundColor Yellow
    exit 1
}

# Navigate to resources directory
$resourcesDir = "pkg\provider\resources"
if (-not (Test-Path $resourcesDir)) {
    Write-Host "Error: Resources directory not found at $resourcesDir" -ForegroundColor Red
    exit 1
}

Write-Host "Generating VP9 test videos (fast version)..." -ForegroundColor Green

# Generate gradient pattern VP9 videos at different resolutions with faster encoding
# Using preset 8 (fastest) and shorter duration for quick generation
& $ffmpegPath -f lavfi -i "gradients=size=320x180:speed=0.1:duration=2" -t 2 `
    -c:v libvpx-vp9 -b:v 150k -deadline realtime -cpu-used 8 `
    -an "$resourcesDir\gradient_180_150.ivf" -y

& $ffmpegPath -f lavfi -i "gradients=size=640x360:speed=0.1:duration=2" -t 2 `
    -c:v libvpx-vp9 -b:v 600k -deadline realtime -cpu-used 8 `
    -an "$resourcesDir\gradient_360_600.ivf" -y

& $ffmpegPath -f lavfi -i "gradients=size=1280x720:speed=0.1:duration=2" -t 2 `
    -c:v libvpx-vp9 -b:v 2000k -deadline realtime -cpu-used 8 `
    -an "$resourcesDir\gradient_720_2000.ivf" -y

& $ffmpegPath -f lavfi -i "gradients=size=1920x1080:speed=0.1:duration=2" -t 2 `
    -c:v libvpx-vp9 -b:v 4000k -deadline realtime -cpu-used 8 `
    -an "$resourcesDir\gradient_1080_4000.ivf" -y

Write-Host "VP9 video generation complete!" -ForegroundColor Green
Write-Host "Generated files:" -ForegroundColor Cyan
Get-ChildItem "$resourcesDir\gradient_*.ivf" | ForEach-Object {
    Write-Host "  - $($_.Name) ($('{0:N2}' -f ($_.Length / 1KB)) KB)"
}