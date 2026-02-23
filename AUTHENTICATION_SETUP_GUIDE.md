# Firebase Authentication Setup Guide

## Current Status
- **Project ID**: emtech-be4d4
- **Package Name**: com.emtech.emtech_school
- **SHA-1 Fingerprint**: `7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2`
- **SHA-256 Fingerprint**: `4D:F0:9A:B9:B6:12:70:7C:F7:B0:7C:B3:00:A1:93:8B:49:85:92:51:2B:48:22:40:83:3E:66:5D:44:60:ED:2C`

## Step 1: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **emtech** (emtech-be4d4)
3. Click on the gear icon ⚙️ next to "Project Overview" → **Project Settings**
4. Scroll down to "Your apps" section
5. Find your Android app: `com.emtech.emtech_school`
6. Click "Add fingerprint" button
7. Add the SHA-1: `7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2`
8. Also add SHA-256: `4D:F0:9A:B9:B6:12:70:7C:F7:B0:7C:B3:00:A1:93:8B:49:85:92:51:2B:48:22:40:83:3E:66:5D:44:60:ED:2C`
9. **IMPORTANT**: Download the updated `google-services.json` file
10. Replace the file in `android/app/google-services.json`

## Step 2: Enable Authentication Methods

### Enable Email/Password Authentication
1. In Firebase Console, go to **Build** → **Authentication**
2. Click **Get Started** (if not already enabled)
3. Go to **Sign-in method** tab
4. Click on **Email/Password**
5. Toggle **Enable** to ON
6. Click **Save**

### Enable Google Sign-In
1. In the same **Sign-in method** tab
2. Click on **Google**
3. Toggle **Enable** to ON
4. Set **Project support email** to: `elitekigali76@gmail.com`
5. Click **Save**
6. Note down the **Web client ID** shown (you'll need this)

## Step 3: Configure OAuth Client IDs (Critical for Google Sign-In)

After enabling Google Sign-In, Firebase automatically creates OAuth 2.0 client IDs in Google Cloud Console:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **emtech-be4d4**
3. Go to **APIs & Services** → **Credentials**
4. You should see automatically created OAuth 2.0 Client IDs:
   - Web client (auto-created by Google Service)
   - Android client (needs manual configuration)

### Verify Android OAuth Client
1. Click on the Android client ID (or create one if missing)
2. Set the following:
   - **Name**: Android client for emtech_school
   - **Package name**: `com.emtech.emtech_school`
   - **SHA-1 certificate fingerprint**: `7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2`
3. Click **Save**

### Get the Web Client ID
1. Find the **Web client (auto-created for Google Sign-in)** or similar
2. Copy the **Client ID** (format: `XXXXXX.apps.googleusercontent.com`)
3. Keep this for the next step

## Step 4: Update Google Sign-In Configuration in Code

The Web Client ID needs to be configured in your Flutter app. This has been automatically updated in the code.

## Step 5: Test Authentication

After completing all steps:

```bash
# Clean and rebuild the app
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..

# Run the app
flutter run
```

## Troubleshooting

### Google Sign-In Errors

**Error**: "Developer Error" or "Sign-in failed"
- **Solution**: Ensure SHA-1 is correctly added to Firebase Console
- Download and replace google-services.json after adding SHA-1

**Error**: "ApiException: 10"
- **Solution**: Package name mismatch or SHA-1 not registered
- Verify package name: `com.emtech.emtech_school`
- Re-check SHA-1 fingerprint

**Error**: "PlatformException: sign_in_failed"
- **Solution**: OAuth client not properly configured
- Verify OAuth client has correct package name and SHA-1

### Email/Password Errors

**Error**: "The email address is badly formatted"
- **Solution**: Validate email format before submission

**Error**: "The password is invalid"
- **Solution**: Check if user exists and password is correct
- Use "Forgot Password" to reset

**Error**: "There is no user record"
- **Solution**: User needs to sign up first

## Quick Test Commands

```bash
# Get SHA-1 again (if needed)
cd android
./gradlew signingReport

# Check Firebase login status
firebase login

# List Firebase projects
firebase projects:list

# Verify current project
firebase use
```

## Important Notes

1. **SHA-1 Fingerprint**: Critical for Google Sign-In on Android
2. **google-services.json**: Must be updated after adding SHA-1
3. **Web Client ID**: Used for server-side verification
4. **Clean Build**: Always clean build after configuration changes
5. **Test on Real Device**: Some auth features may not work perfectly on emulators

## Support

If you continue to experience issues:
1. Check Firebase Console → Authentication → Users (to see if users are being created)
2. Check Android Logcat for detailed error messages: `flutter logs`
3. Verify all credentials and IDs match between Firebase and your app
