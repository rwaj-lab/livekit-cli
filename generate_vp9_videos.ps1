# Generate VP9 video files for testing
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

Write-Host "Generating VP9 test videos..." -ForegroundColor Green

# Generate gradient pattern VP9 videos at different resolutions
# Using gradient pattern for visual variation
& $ffmpegPath -f lavfi -i "gradients=size=320x180:speed=0.1:duration=10" -t 10 `
    -c:v libvpx-vp9 -b:v 150k -crf 30 -g 30 -keyint_min 30 -tile-columns 0 `
    -an "$resourcesDir\gradient_180_150.ivf" -y

& $ffmpegPath -f lavfi -i "gradients=size=640x360:speed=0.1:duration=10" -t 10 `
    -c:v libvpx-vp9 -b:v 600k -crf 28 -g 30 -keyint_min 30 -tile-columns 1 `
    -an "$resourcesDir\gradient_360_600.ivf" -y

& $ffmpegPath -f lavfi -i "gradients=size=1280x720:speed=0.1:duration=10" -t 10 `
    -c:v libvpx-vp9 -b:v 2000k -crf 26 -g 60 -keyint_min 60 -tile-columns 2 `
    -an "$resourcesDir\gradient_720_2000.ivf" -y

& $ffmpegPath -f lavfi -i "gradients=size=1920x1080:speed=0.1:duration=10" -t 10 `
    -c:v libvpx-vp9 -b:v 4000k -crf 24 -g 60 -keyint_min 60 -tile-columns 2 -threads 4 `
    -an "$resourcesDir\gradient_1080_4000.ivf" -y

# Generate mandelbrot pattern VP9 videos
& $ffmpegPath -f lavfi -i "mandelbrot=size=320x180:rate=15" -t 10 `
    -c:v libvpx-vp9 -b:v 150k -crf 30 -g 30 -keyint_min 30 -tile-columns 0 `
    -an "$resourcesDir\mandelbrot_180_150.ivf" -y

& $ffmpegPath -f lavfi -i "mandelbrot=size=640x360:rate=20" -t 10 `
    -c:v libvpx-vp9 -b:v 600k -crf 28 -g 30 -keyint_min 30 -tile-columns 1 `
    -an "$resourcesDir\mandelbrot_360_600.ivf" -y

& $ffmpegPath -f lavfi -i "mandelbrot=size=1280x720:rate=30" -t 10 `
    -c:v libvpx-vp9 -b:v 2000k -crf 26 -g 60 -keyint_min 60 -tile-columns 2 `
    -an "$resourcesDir\mandelbrot_720_2000.ivf" -y

& $ffmpegPath -f lavfi -i "mandelbrot=size=1920x1080:rate=30" -t 10 `
    -c:v libvpx-vp9 -b:v 4000k -crf 24 -g 60 -keyint_min 60 -tile-columns 2 -threads 4 `
    -an "$resourcesDir\mandelbrot_1080_4000.ivf" -y

Write-Host "VP9 video generation complete!" -ForegroundColor Green
Write-Host "Generated files:" -ForegroundColor Cyan
Get-ChildItem "$resourcesDir\*gradient*.ivf", "$resourcesDir\*mandelbrot*.ivf" | ForEach-Object {
    Write-Host "  - $($_.Name) ($('{0:N2}' -f ($_.Length / 1MB)) MB)"
}