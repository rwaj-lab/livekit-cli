# PowerShell script to generate missing H.264 1080p files
# Run this after FFmpeg is installed

Write-Host "Generating 1080p H.264 files for LiveKit CLI" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check if FFmpeg is installed
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    # Try to find FFmpeg in common locations
    $ffmpegPath = "C:\Users\rwaj\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-7.1.1-full_build\bin\ffmpeg.exe"
    if (Test-Path $ffmpegPath) {
        $ffmpeg = @{ Path = $ffmpegPath }
        Write-Host "FFmpeg found at: $ffmpegPath" -ForegroundColor Green
    } else {
        Write-Host "ERROR: FFmpeg is not installed or not found!" -ForegroundColor Red
        Write-Host "Please install FFmpeg first:" -ForegroundColor Yellow
        Write-Host "  winget install Gyan.FFmpeg" -ForegroundColor Cyan
        exit 1
    }
} else {
    Write-Host "FFmpeg found at: $($ffmpeg.Path)" -ForegroundColor Green
}
Write-Host ""

# Change to project directory
$projectPath = "C:\Users\rwaj\Documents\project\livekit-cli"
Set-Location $projectPath
Write-Host "Working directory: $projectPath" -ForegroundColor Cyan
Write-Host ""

# Create resources directory if it doesn't exist
$resourcePath = "pkg\provider\resources"
if (-not (Test-Path $resourcePath)) {
    New-Item -ItemType Directory -Path $resourcePath -Force | Out-Null
    Write-Host "Created directory: $resourcePath" -ForegroundColor Yellow
}

# Function to generate a video file
function Generate-Video {
    param(
        [string]$Name,
        [string]$Input,
        [string]$Size,
        [string]$Bitrate,
        [string]$FileName
    )
    
    $outputFile = Join-Path $resourcePath $FileName
    Write-Host "Generating: $Name" -ForegroundColor Yellow
    Write-Host "  Output: $outputFile" -ForegroundColor Gray
    
    $args = @(
        "-f", "lavfi",
        "-i", "$Input=size=$($Size):rate=30,format=yuv420p",
        "-t", "10",
        "-c:v", "libx264",
        "-preset", "fast",
        "-profile:v", "baseline",
        "-level", "4.0",
        "-b:v", $Bitrate,
        "-maxrate", $Bitrate,
        "-bufsize", "$([int]($Bitrate -replace 'k','') * 2)k",
        "-x264-params", "keyint=60:min-keyint=60:no-scenecut",
        "-an",
        $outputFile,
        "-y"
    )
    
    # Use the ffmpeg executable path
    if ($ffmpeg.Path) {
        & $ffmpeg.Path @args 2>&1 | Out-Null
    } else {
        & "C:\Users\rwaj\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-7.1.1-full_build\bin\ffmpeg.exe" @args 2>&1 | Out-Null
    }
    
    if (Test-Path $outputFile) {
        $size = (Get-Item $outputFile).Length / 1MB
        $sizeStr = "{0:F2}" -f $size
        Write-Host "  [OK] Generated successfully ($sizeStr MB)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Failed to generate!" -ForegroundColor Red
    }
    Write-Host ""
}

# Generate the three missing H.264 files
Write-Host "Starting H.264 file generation..." -ForegroundColor Green
Write-Host ""

Generate-Video `
    -Name "Butterfly Pattern (1080p)" `
    -Input "testsrc2" `
    -Size "1920x1080" `
    -Bitrate "4000k" `
    -FileName "butterfly_1080_4000.h264"

Generate-Video `
    -Name "Cartoon Pattern (1080p)" `
    -Input "testsrc" `
    -Size "1920x1080" `
    -Bitrate "3500k" `
    -FileName "cartoon_1080_3500.h264"

Generate-Video `
    -Name "Circles Pattern (1080p Portrait)" `
    -Input "testsrc2" `
    -Size "1080x1920" `
    -Bitrate "4000k" `
    -FileName "circles_p1080_4000.h264"

# Verify all files exist
Write-Host "Verification - All 1080p files:" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

$allFiles = @(
    "butterfly_1080_4000.h264",
    "cartoon_1080_3500.h264",
    "circles_p1080_4000.h264",
    "crescent_1080_4000.ivf",
    "neon_1080_4000.ivf",
    "tunnel_1080_4000.ivf"
)

$allPresent = $true
foreach ($file in $allFiles) {
    $path = Join-Path $resourcePath $file
    if (Test-Path $path) {
        $size = (Get-Item $path).Length / 1MB
        $sizeStr = "{0:F2}" -f $size
        Write-Host "  [OK] $file ($sizeStr MB)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
        $allPresent = $false
    }
}

Write-Host ""
if ($allPresent) {
    Write-Host "SUCCESS: All 1080p files are ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Rebuild the project: go build -o lk.exe ./cmd/lk" -ForegroundColor Cyan
    Write-Host "2. Test: .\lk.exe load-test --video-resolution very-high --video-publishers 2 --duration 10s --api-key devkey --api-secret devsecret --url ws://localhost:7880" -ForegroundColor Cyan
} else {
    Write-Host "WARNING: Some files are missing!" -ForegroundColor Yellow
    Write-Host "Make sure FFmpeg is installed and try again." -ForegroundColor Yellow
}