# LiveKit CLI Video Resolution Verification Script for Windows PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LiveKit CLI Video Resolution Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set binary name
$LK_BIN = ".\lk.exe"

Write-Host "Using binary: $LK_BIN" -ForegroundColor Gray
Write-Host ""

# Check if binary exists
if (-not (Test-Path $LK_BIN)) {
    Write-Host "Error: $LK_BIN not found. Please build the project first:" -ForegroundColor Red
    Write-Host '  go build -o lk.exe ./cmd/lk' -ForegroundColor Yellow
    exit 1
}

# Check LiveKit server connection
Write-Host "Checking LiveKit server..." -ForegroundColor Yellow
$serverTest = & $LK_BIN load-test --video-publishers 0 --duration 1s --api-key devkey --api-secret devsecret --url ws://localhost:7880 2>&1
if ($serverTest -notmatch "Finished connecting") {
    Write-Host "Warning: LiveKit server may not be running on ws://localhost:7880" -ForegroundColor Yellow
    Write-Host 'Start it with: docker run -d --rm -p 7880:7880 -p 7881:7881 -p 7882:7882/udp -e LIVEKIT_KEYS="devkey: devsecret" --name livekit-server livekit/livekit-server --dev --node-ip=127.0.0.1' -ForegroundColor Gray
    Write-Host ""
}

# Define test cases
$testCases = @(
    @{Resolution="very-high"; Description="1080p+720p+360p simulcast"},
    @{Resolution="high"; Description="720p+360p+180p simulcast"},
    @{Resolution="medium"; Description="360p+180p simulcast"},
    @{Resolution="low"; Description="180p single layer"},
    @{Resolution="1080,720,360"; Description="Custom 1080p+720p+360p"},
    @{Resolution="1080,720"; Description="Custom 1080p+720p"},
    @{Resolution="1080"; Description="Custom 1080p only"},
    @{Resolution="720,360"; Description="Custom 720p+360p"},
    @{Resolution="360"; Description="Custom 360p only"}
)

# Function to test resolution
function Test-Resolution {
    param(
        [string]$Resolution,
        [string]$Description,
        [int]$TestNum,
        [int]$Total
    )
    
    Write-Host "[$TestNum/$Total] " -NoNewline -ForegroundColor Yellow
    Write-Host "Testing: --video-resolution $Resolution"
    Write-Host "         Description: $Description" -ForegroundColor Gray
    
    # Run the test
    $output = & $LK_BIN load-test --video-resolution $Resolution `
        --video-publishers 1 --duration 2s `
        --api-key devkey --api-secret devsecret `
        --url ws://localhost:7880 2>&1 | Out-String
    
    # Check if test ran successfully
    if ($output -match "INFO:") {
        Write-Host "         [OK] Resolution mode working" -ForegroundColor Green
        
        # Check for 1080p files
        if ($Resolution -match "1080" -or $Resolution -eq "very-high") {
            if ($output -match "Using actual 1080p file") {
                Write-Host "         [OK] Using actual 1080p files" -ForegroundColor Green
            }
            elseif ($output -match "falling back to 720p") {
                Write-Host "         [WARN] Falling back to 720p (1080p files missing)" -ForegroundColor Yellow
            }
        }
        
        # Extract layer information
        if ($output -match "Simulcast mode.*using (\d+) layers: (.*)") {
            $layers = $Matches[2]
            Write-Host "         Layers: $layers" -ForegroundColor Gray
        }
        elseif ($output -match "Non-simulcast mode.*single layer at (.*)") {
            $layer = $Matches[1]
            Write-Host "         Single layer: $layer" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "         [FAIL] Failed to test resolution" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Run resolution tests
Write-Host "Starting Resolution Tests" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

$testNum = 1
foreach ($test in $testCases) {
    Test-Resolution -Resolution $test.Resolution -Description $test.Description -TestNum $testNum -Total $testCases.Count
    $testNum++
}

# Test --no-simulcast flag
Write-Host "Testing --no-simulcast Flag" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[Special Test 1] " -NoNewline -ForegroundColor Yellow
Write-Host "Testing: --video-resolution very-high --no-simulcast"

$output = & $LK_BIN load-test --video-resolution "very-high" --no-simulcast `
    --video-publishers 1 --duration 2s `
    --api-key devkey --api-secret devsecret `
    --url ws://localhost:7880 2>&1 | Out-String

if ($output -match "Non-simulcast mode") {
    Write-Host "         [OK] No-simulcast mode working (sends only highest resolution)" -ForegroundColor Green
}
else {
    Write-Host "         [FAIL] No-simulcast test failed" -ForegroundColor Red
}
Write-Host ""

# Check for 1080p video files
Write-Host "Checking 1080p Video Files" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host ""

$h264Files = @("butterfly_1080_4000.h264", "cartoon_1080_3500.h264", "circles_p1080_4000.h264")
$ivfFiles = @("crescent_1080_4000.ivf", "neon_1080_4000.ivf", "tunnel_1080_4000.ivf")

$h264Count = 0
$ivfCount = 0

foreach ($file in $h264Files) {
    $path = "pkg\provider\resources\$file"
    if (Test-Path $path) {
        $size = [math]::Round((Get-Item $path).Length / 1MB, 2)
        Write-Host "[OK] $file ($size MB)" -ForegroundColor Green
        $h264Count++
    }
    else {
        Write-Host "[MISSING] $file" -ForegroundColor Red
    }
}

foreach ($file in $ivfFiles) {
    $path = "pkg\provider\resources\$file"
    if (Test-Path $path) {
        $size = [math]::Round((Get-Item $path).Length / 1MB, 2)
        Write-Host "[OK] $file ($size MB)" -ForegroundColor Green
        $ivfCount++
    }
    else {
        Write-Host "[MISSING] $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "=======" -ForegroundColor Cyan
Write-Host "H.264 files: $h264Count/3"
Write-Host "VP8/IVF files: $ivfCount/3"

if ($h264Count -eq 3 -and $ivfCount -eq 3) {
    Write-Host "[OK] All 1080p files present - Full 1080p support enabled" -ForegroundColor Green
}
elseif ($h264Count -gt 0 -or $ivfCount -gt 0) {
    Write-Host "[WARN] Some 1080p files missing - Partial 1080p support" -ForegroundColor Yellow
    Write-Host "       Run generate_h264_files.ps1 to create missing files" -ForegroundColor Gray
}
else {
    Write-Host "[WARN] No 1080p files found - Using 720p fallback" -ForegroundColor Yellow
    Write-Host "       Run generate_h264_files.ps1 to enable full 1080p support" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Verification complete!" -ForegroundColor Green