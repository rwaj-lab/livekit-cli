# Install Go and Build LiveKit CLI

## Option 1: Install Go via Winget (Recommended)

Open PowerShell or Command Prompt as Administrator and run:

```powershell
winget install GoLang.Go
```

After installation, restart your terminal and verify:
```bash
go version
```

## Option 2: Manual Go Installation

1. Download Go from: https://go.dev/dl/
2. Download the Windows installer (go1.23.x.windows-amd64.msi)
3. Run the installer
4. Restart your terminal

## Build the Project

Once Go is installed:

```bash
# Navigate to the project directory
cd C:\Users\rwaj\Documents\project\livekit-cli

# Download dependencies
go mod download

# Build the executable
go build -o lk.exe ./cmd/lk

# Verify the build
.\lk.exe --version
```

## Quick Test

After building, test the new 1080p feature:

```bash
# Show help to verify new options
.\lk.exe load-test --help

# Quick test with very-high resolution (if you have a LiveKit server)
.\lk.exe load-test --video-resolution very-high --video-publishers 1 --duration 10s
```

## Alternative: Download Pre-built Binary

If you want to test without building:

1. Go to: https://github.com/livekit/livekit-cli/releases/latest
2. Download `livekit-cli_<version>_windows_amd64.tar.gz`
3. Extract the archive
4. The binary will be named `lk.exe`

**Note**: The pre-built binary won't have our 1080p changes. You need to build from source to test the new features.

## Verify Our Changes

After building, you can verify our 1080p implementation:

```bash
# Check the help text includes our new options
.\lk.exe load-test --help | findstr "very-high"

# The output should show:
# Resolution QUALITY of video to publish. Options: "very-high" (1080p+720p+360p)...
```

## If Build Fails

Common issues and solutions:

1. **"go: command not found"**
   - Go is not installed or not in PATH
   - Restart terminal after installation

2. **Module errors**
   ```bash
   go clean -modcache
   go mod download
   ```

3. **Permission errors**
   - Run terminal as Administrator
   - Or build in a different directory

4. **Git LFS errors**
   - Install Git LFS: `git lfs install`
   - Pull LFS files: `git lfs pull`