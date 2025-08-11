@echo off
echo Testing 1080p Load Test Logging
echo ================================
echo.

echo Test 1: very-high resolution (should show fallback to 720p if no 1080p files)
echo --------------------------------------------------------------------------------
lk.exe load-test --video-resolution very-high --video-publishers 1 --duration 5s --api-key devkey --api-secret devsecret --url ws://localhost:7880
echo.

echo Test 2: Custom resolution 1080,720
echo --------------------------------------------------------------------------------
lk.exe load-test --video-resolution "1080,720" --video-publishers 1 --duration 5s --api-key devkey --api-secret devsecret --url ws://localhost:7880
echo.

echo Test 3: Standard high resolution (no 1080p)
echo --------------------------------------------------------------------------------
lk.exe load-test --video-resolution high --video-publishers 1 --duration 5s --api-key devkey --api-secret devsecret --url ws://localhost:7880
echo.

echo.
echo Tests complete. Check the INFO logs above to see:
echo - Whether 1080p files were found or fallback to 720p was used
echo - Which resolution layers were created
echo - Whether simulcast or single layer mode was used