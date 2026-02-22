# Firebase Remote Config Setup for Agora

This guide explains how to securely store your Agora App ID in Firebase Remote Config so it's not exposed in your GitHub repository.

## ✅ Current Setup

Your Agora App ID is now stored securely in two places:

1. **Local Development**: `lib/config/agora_config_local.dart` (gitignored)
   - Contains your actual App ID: `6994ddd5b9674386b5602fb67fbb2c9e`
   - This file is **NOT** committed to GitHub
   - Used for local development and testing

2. **Production (Optional)**: Firebase Remote Config
   - Allows you to update the App ID without rebuilding the app
   - Good for production deployments
   - Can be used across all devices

## Quick Start (Already Working!)

Your app is already configured and ready to use! The App ID is in the local config file, which is gitignored and won't be committed to GitHub.

**You can start testing immediately:**
```bash
flutter pub get
flutter run
```

## Optional: Set Up Firebase Remote Config (For Production)

If you want to use Firebase Remote Config for production deployments, follow these steps:

### Step 1: Access Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or the one used for Emtech School)
3. In the left sidebar, click on **"Remote Config"** under the "Engage" section

### Step 2: Create Parameters

Click **"Add parameter"** and create the following:

#### Parameter 1: agora_app_id
- **Parameter key**: `agora_app_id`
- **Default value**: `6994ddd5b9674386b5602fb67fbb2c9e`
- **Description**: Agora App ID for voice calling
- **Value type**: String

#### Parameter 2: agora_temp_token (Optional)
- **Parameter key**: `agora_temp_token`
- **Default value**: (leave empty or add your temp token)
- **Description**: Temporary Agora token for testing
- **Value type**: String

### Step 3: Publish Changes

1. Click **"Publish changes"** in the Firebase Remote Config page
2. Add a description like "Add Agora configuration"
3. Click **"Publish"**

### Step 4: Test the Configuration

Your app will automatically fetch these values on startup. To verify:

1. Run your app: `flutter run`
2. Check the console logs for: `✅ Firebase Remote Config initialized`
3. Test the call feature from the Support page

## How It Works

The app uses a smart fallback system:

```
1. Try local config (agora_config_local.dart) ← Development
   ↓ If not available
2. Try Firebase Remote Config ← Production
   ↓ If not available
3. Return empty string (app will show "not configured" message)
```

### Priority Order:
1. **Local Config** (highest priority) - for development
2. **Firebase Remote Config** - for production
3. **Empty/Not configured** - shows error message

## Benefits of This Approach

✅ **Secure**: App ID is never committed to GitHub
✅ **Flexible**: Can update config without rebuilding the app (when using Remote Config)
✅ **Developer-Friendly**: Local config for easy development
✅ **Production-Ready**: Remote Config for live deployments

## Testing

### Test Local Config (Development)
```bash
# The app is already configured with your App ID
flutter run
```

### Test Remote Config (Production Simulation)
To test if Remote Config is working:

1. Temporarily rename `agora_config_local.dart`:
   ```bash
   mv lib/config/agora_config_local.dart lib/config/agora_config_local.dart.backup
   ```

2. Run the app:
   ```bash
   flutter run
   ```

3. The app should fetch the App ID from Firebase Remote Config

4. Restore the local config:
   ```bash
   mv lib/config/agora_config_local.dart.backup lib/config/agora_config_local.dart
   ```

## Remote Config Settings

You can customize the fetch behavior in `lib/config/agora_config.dart`:

```dart
await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
  fetchTimeout: const Duration(seconds: 10),      // Max time to fetch
  minimumFetchInterval: const Duration(hours: 1), // Cache duration
));
```

### Recommended Settings:
- **Development**: `minimumFetchInterval: Duration(minutes: 1)` - fast updates
- **Production**: `minimumFetchInterval: Duration(hours: 12)` - reduce bandwidth

## Troubleshooting

### Issue: App shows "not configured" message

**Solutions:**
1. Check if `agora_config_local.dart` exists and has the App ID
2. If using Remote Config, ensure parameters are published in Firebase Console
3. Check internet connection (Remote Config needs internet)
4. Check console logs for error messages

### Issue: Changes to Remote Config not reflecting

**Solutions:**
1. Clear app data and restart
2. In the app, call `AgoraConfig.refresh()` to force fetch
3. Check `minimumFetchInterval` - it might be caching old values
4. Wait for the fetch interval to expire

### Issue: Local config file missing after git clone

**This is expected!** The file is gitignored for security. To fix:

1. Create the file manually:
   ```bash
   touch lib/config/agora_config_local.dart
   ```

2. Add your App ID:
   ```dart
   class AgoraConfigLocal {
     static const String appId = 'YOUR_APP_ID_HERE';
     static const String tempToken = '';
   }
   ```

Or use Firebase Remote Config for the team to share configuration.

## Advanced: Conditional Configs

You can set different values for different conditions in Firebase Remote Config:

### By Platform (iOS/Android)
1. In Firebase Console, click on a parameter
2. Click "Add value for condition"
3. Create condition: "Platform = iOS" or "Platform = Android"
4. Set different App IDs if needed

### By App Version
1. Create condition: "App version >= 1.2.0"
2. Useful for gradual rollouts

### By User Segment
1. Create condition: "User in segment: beta_testers"
2. Test new configs with specific users

## Security Best Practices

✅ **Do's:**
- ✅ Keep `agora_config_local.dart` in `.gitignore`
- ✅ Use Firebase Remote Config for production
- ✅ Rotate tokens regularly
- ✅ Use token server for production (not temp tokens)
- ✅ Monitor Agora usage in console

❌ **Don'ts:**
- ❌ Never commit App ID or tokens to Git
- ❌ Don't share `agora_config_local.dart` file directly
- ❌ Don't use temporary tokens in production
- ❌ Don't expose App ID in client-side logs (in production builds)

## For Team Members

When a team member clones the repository:

### Option 1: Use Remote Config (Recommended for Production)
- No setup needed! The app will fetch from Firebase automatically
- Requires Firebase access permissions

### Option 2: Create Local Config (Development)
1. Ask team lead for the Agora App ID
2. Create `lib/config/agora_config_local.dart`
3. Add the App ID as shown in the template above

## Monitoring

### View Remote Config Usage
1. Go to Firebase Console → Remote Config
2. Check "Fetch and activation metrics"
3. Monitor active users and fetch success rate

### View Agora Usage
1. Go to [Agora Console](https://console.agora.io/)
2. Check "Usage" to see call minutes
3. Monitor costs and stay within free tier (10,000 min/month)

## Summary

🎉 **You're all set!** Your Agora App ID is securely configured and won't be committed to GitHub.

- **Now**: Using local config (development ready)
- **Later**: Optionally set up Remote Config for production
- **Always**: App ID stays private and secure

For any questions, refer to:
- Main setup guide: `AGORA_SETUP_GUIDE.md`
- Agora docs: https://docs.agora.io/
- Firebase Remote Config: https://firebase.google.com/docs/remote-config
