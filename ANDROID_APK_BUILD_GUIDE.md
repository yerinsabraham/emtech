# Building Android APK with Agora Support

This guide explains how to build an Android APK with Agora calling functionality.

## ✅ Quick Answer

**Yes!** Agora works perfectly on Android APK builds (both debug and release).

## 📱 Building APK

### Debug APK (For Testing)

```bash
# Build debug APK
flutter build apk --debug

# Output location:
# build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (For Production)

```bash
# Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs by Architecture (Smaller file size)

```bash
# Build separate APKs for different CPU architectures
flutter build apk --split-per-abi

# Generates 3 APKs:
# - app-armeabi-v7a-release.apk (32-bit ARM)
# - app-arm64-v8a-release.apk (64-bit ARM) ← Most common
# - app-x86_64-release.apk (Intel/AMD 64-bit)
```

## 🔧 What's Configured for Android

### 1. Permissions (Already Added)
All necessary permissions are in `android/app/src/main/AndroidManifest.xml`:
- ✅ INTERNET - For Agora connection
- ✅ RECORD_AUDIO - For microphone
- ✅ CAMERA - For future video calls
- ✅ MODIFY_AUDIO_SETTINGS - For audio control
- ✅ ACCESS_NETWORK_STATE - For connection status
- ✅ BLUETOOTH - For Bluetooth audio
- ✅ ACCESS_WIFI_STATE - For WiFi status

### 2. ProGuard Rules (For Release Builds)
ProGuard rules are in `android/app/proguard-rules.pro` to prevent Agora code from being obfuscated in release builds.

### 3. Build Configuration
`android/app/build.gradle.kts` is configured with:
- ✅ ProGuard enabled for release builds
- ✅ Resource shrinking enabled
- ✅ Agora-specific keep rules

## 📦 Installation

### Install Debug APK
```bash
# Build and install on connected device
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Install Release APK
```bash
# Build and install on connected device
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

Or simply transfer the APK to your phone and install it.

## ⚠️ Runtime Permissions

On Android 6.0+ (API level 23+), users must grant permissions at runtime:

1. **First call**: App will request microphone permission
2. **User must allow**: Otherwise calls won't work
3. **Already handled**: The `permission_handler` package in the app handles this automatically

### Testing Permissions

When you first make a call, you'll see:
```
"Emtech School wants to record audio"
[Deny] [Allow]
```

Tap **Allow** for calling to work.

## 🧪 Testing APK

### 1. Build Debug APK
```bash
flutter build apk --debug
```

### 2. Install on Device
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 3. Test Call Feature
1. Open the app
2. Go to Profile → Support
3. Click "Call Support"
4. Allow microphone permission when prompted
5. Call should connect!

### 4. Test with Two Devices
- **Device 1**: Regular user account → Make call
- **Device 2**: Admin account → Receive call

## 🚀 Production Release

### Before Publishing to Play Store

1. **Sign Your APK**: Configure signing in `android/app/build.gradle.kts`
   ```kotlin
   signingConfigs {
       release {
           storeFile = file("your-keystore.jks")
           storePassword = "your-password"
           keyAlias = "your-alias"
           keyPassword = "your-key-password"
       }
   }
   ```

2. **Build Signed Release APK**:
   ```bash
   flutter build apk --release
   ```

3. **Or Build App Bundle** (recommended for Play Store):
   ```bash
   flutter build appbundle --release
   ```

## 🔍 Troubleshooting

### Issue: Microphone permission not working

**Solution**: Check that permissions are in `AndroidManifest.xml` and request at runtime:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### Issue: App crashes on release build

**Solution**: Ensure ProGuard rules are properly configured in `proguard-rules.pro`

### Issue: "Failed to join channel" on APK

**Solution**: 
1. Check internet connectivity
2. Verify Agora App ID is configured
3. Ensure token server is deployed (for secured mode)
4. Check Firebase connectivity

### Issue: APK size too large

**Solution**: Build split APKs:
```bash
flutter build apk --split-per-abi
```

This creates separate APKs for each architecture, reducing size by ~30%.

## 📊 APK Size Comparison

| Build Type | Approximate Size |
|------------|------------------|
| Debug APK | ~50-70 MB |
| Release APK | ~30-40 MB |
| Split APK (arm64) | ~20-25 MB |

## ✅ Agora-Specific Considerations

### 1. Network Connectivity
- Agora requires **stable internet** (WiFi or mobile data)
- Minimum recommended: 2G for voice calls
- Better experience: 3G/4G/5G or WiFi

### 2. Audio Quality
- **Good**: WiFi or 4G/5G connection
- **Fair**: 3G connection
- **Poor**: 2G connection (may drop calls)

### 3. Battery Usage
- Voice calls: Low to moderate battery usage
- Background calls: Minimal impact
- Recommendation: Warn users on low battery

## 🔐 Security Notes

### Release APK
- ✅ Agora App ID is read from local config (gitignored)
- ✅ Tokens generated securely via Cloud Function
- ✅ ProGuard obfuscates your code
- ✅ No hardcoded credentials in APK

### Debug APK
- ⚠️ Debug builds include more debugging info
- ⚠️ Use only for testing, not distribution
- ✅ Same security as release for Agora calls

## 📱 Minimum Requirements

- **Android Version**: 5.0 (API level 21) or higher
- **RAM**: 2GB+ recommended
- **Storage**: 100MB+ free space
- **Network**: Internet connection required

## 🎯 Summary

✅ **Agora works on Android APK** - Both debug and release builds  
✅ **Permissions configured** - Microphone and network access  
✅ **ProGuard configured** - Release builds won't break Agora  
✅ **Runtime permissions handled** - Automatic permission requests  
✅ **Optimized builds** - Split APKs for smaller file size  

Build your APK now:
```bash
flutter build apk --release
```

And test the calling feature! 📞🎉
