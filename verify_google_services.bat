@echo off
echo.
echo ========================================================================
echo Google Sign-In SHA-1 Verification Tool
echo ========================================================================
echo.

REM Check if google-services.json exists in root
if exist "google-services.json" (
    echo [1/3] Checking google-services.json in project root...
    echo.
    findstr /C:"client_type" google-services.json > nul
    if %errorlevel% equ 0 (
        echo Found OAuth clients in google-services.json
        echo.
        echo Checking for Android OAuth client (client_type: 1)...
        findstr /C:"\"client_type\": 1" google-services.json > nul
        if %errorlevel% equ 0 (
            echo.
            echo ✓ SUCCESS: Android OAuth client found!
            echo ✓ SHA-1 fingerprint is properly configured
            echo.
            echo [2/3] Moving file to android\app\...
            move /Y google-services.json android\app\google-services.json
            echo.
            echo ✓ File moved successfully
            echo.
            echo [3/3] Next steps:
            echo    Run: flutter clean
            echo    Run: flutter pub get
            echo    Run: flutter run
            echo.
            echo Google Sign-In should now work!
            pause
            exit /b 0
        ) else (
            echo.
            echo ✗ MISSING: Android OAuth client NOT found
            echo ✗ The SHA-1 fingerprint was not added correctly
            echo.
            echo Please follow these steps:
            echo 1. Go to Firebase Console Project Settings
            echo 2. Find your Android app: com.emtech.emtech_school
            echo 3. Add SHA-1: 7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2
            echo 4. Click Save
            echo 5. Download the NEW google-services.json
            echo 6. Run this script again
            echo.
            pause
            exit /b 1
        )
    )
) else if exist "android\app\google-services.json" (
    echo [1/2] Checking google-services.json in android\app\...
    echo.
    findstr /C:"\"client_type\": 1" android\app\google-services.json > nul
    if %errorlevel% equ 0 (
        echo.
        echo ✓ SUCCESS: Android OAuth client found!
        echo ✓ SHA-1 fingerprint is properly configured
        echo.
        echo [2/2] The file is already in the correct location
        echo.
        echo Next steps:
        echo    Run: flutter clean
        echo    Run: flutter pub get  
        echo    Run: flutter run
        echo.
        echo Google Sign-In should now work!
    ) else (
        echo.
        echo ✗ PROBLEM: Android OAuth client NOT found
        echo ✗ Your SHA-1 fingerprint is not registered
        echo.
        echo Current SHA-1: 7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2
        echo.
        echo Please add it to Firebase Console:
        echo https://console.firebase.google.com/project/emtech-be4d4/settings/general
        echo.
        echo Then download the NEW google-services.json and run this again
    )
    echo.
    pause
) else (
    echo ✗ ERROR: google-services.json not found!
    echo.
    echo Expected locations:
    echo    - google-services.json (project root)
    echo    - android\app\google-services.json
    echo.
    echo Please download it from Firebase Console and place in project root
    echo.
    pause
    exit /b 1
)
