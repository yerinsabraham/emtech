@echo off
echo.
echo ============================================================================
echo Firebase Authentication Setup - emtech
echo ============================================================================
echo.
echo Your SHA-1 Fingerprint: 7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2
echo Package Name: com.emtech.emtech_school
echo Project ID: emtech-be4d4
echo.
echo ============================================================================
echo IMPORTANT: Follow these steps in Firebase Console
echo ============================================================================
echo.
echo 1. Go to Firebase Console and add your SHA-1 fingerprint
echo 2. Download the NEW google-services.json file
echo 3. Replace android\app\google-services.json with the new file
echo 4. Enable Email/Password authentication
echo 5. Enable Google Sign-In authentication
echo.
echo Opening Firebase Console...
start https://console.firebase.google.com/project/emtech-be4d4/settings/general
echo.
echo Opening Authentication Settings...
timeout /t 2 > nul
start https://console.firebase.google.com/project/emtech-be4d4/authentication/providers
echo.
echo ============================================================================
echo After completing the above steps, run:
echo ============================================================================
echo.
echo   flutter clean
echo   flutter pub get
echo   flutter run
echo.
echo See AUTHENTICATION_SETUP_GUIDE.md for detailed instructions
echo.
pause
