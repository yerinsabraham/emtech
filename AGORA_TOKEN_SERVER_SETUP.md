# Agora Token Server Setup Guide

This guide will help you set up a secure token server using Firebase Cloud Functions for production use of Agora voice calling.

## Why You Need a Token Server

- **Security**: Tokens generated in Agora Console expire after 24 hours
- **Production-Ready**: Tokens are generated on-demand for each call
- **Scalable**: Automatically scales with your user base
- **Secure**: App Certificate is stored securely in Firebase, not in your app code

## Prerequisites

- ✅ Agora account with App ID: `6994ddd5b9674386b5602fb67fbb2c9e`
- ✅ Firebase project set up
- ✅ Firebase CLI installed (if not, see step 1)

## Setup Steps

### Step 1: Install Firebase CLI (if not installed)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login
```

### Step 2: Get Your Agora App Certificate

1. Go to [Agora Console](https://console.agora.io/)
2. Click on your project ("Emtech School Support")
3. Click on the **"Config"** or **"Edit"** button
4. Find **"App Certificate"** section
5. If not enabled, click **"Enable"** to generate it
6. **Copy the App Certificate** (looks like: `abc123def456...`)

### Step 3: Install Function Dependencies

```bash
# Navigate to functions directory
cd functions

# Install Node.js dependencies
npm install

# Go back to project root
cd ..
```

### Step 4: Configure Agora Credentials in Firebase

Set your Agora credentials as environment variables in Firebase Functions:

```bash
# Set App ID
firebase functions:config:set agora.app_id="6994ddd5b9674386b5602fb67fbb2c9e"

# Set App Certificate (replace with your actual certificate)
firebase functions:config:set agora.app_certificate="YOUR_APP_CERTIFICATE_HERE"
```

**Example:**
```bash
firebase functions:config:set agora.app_certificate="abc123def456ghi789jkl012mno345pqr678"
```

### Step 5: Verify Configuration

Check that your configuration is set correctly:

```bash
firebase functions:config:get
```

You should see:
```json
{
  "agora": {
    "app_id": "6994ddd5b9674386b5602fb67fbb2c9e",
    "app_certificate": "your_certificate_here"
  }
}
```

### Step 6: Deploy Cloud Functions

Deploy the functions to Firebase:

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:generateAgoraToken
```

First deployment may take 2-5 minutes. You'll see:
```
✔  functions[generateAgoraToken(us-central1)] Successful create operation.
✔  Deploy complete!
```

### Step 7: Test the Token Generation

You can test the function in the Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Functions** in the left sidebar
4. Click on **generateAgoraToken**
5. Click **"Logs"** to see activity

Or test from your app by making a call!

### Step 8: Update Your App (Already Done!)

The app is already configured to use the Cloud Function. It will:

1. **Try Cloud Function first** (production)
2. **Fall back to local token** (development with `agora_config_local.dart`)
3. **Fall back to APP ID only** (if no token available)

### Step 9: Run Your App

```bash
# Install/update dependencies
flutter pub get

# For iOS
cd ios && pod install && cd ..

# Run the app
flutter run
```

## Testing the Setup

### Test the Token Server

1. **Make a call as a user**: Profile → Support → "Call Support"
2. **Check Flutter console** for logs:
   - `✅ Token generated from Cloud Function` = Token server working!
   - `⚠️ Cloud Function not available, trying local token` = Using fallback
3. **Check Firebase Functions logs**:
   ```bash
   firebase functions:log --only generateAgoraToken
   ```

### Verify It's Working

When calling, you should see in the console:
```
✅ Token generated from Cloud Function
✅ Joined channel: support_call_1234567890
```

## Cost Implications

### Firebase Functions

- **Free Tier**: 2 million invocations/month
- **After Free Tier**: $0.40 per million invocations
- **Estimated Cost**: For 10,000 calls/month = ~$0.02/month

### Agora

- **Free Tier**: 10,000 minutes/month
- **After Free Tier**: Varies by region (~$0.99-$3.99 per 1000 minutes)

**Total estimated cost for moderate use: < $5/month**

## Security Features

✅ **App Certificate never exposed** to client apps
✅ **Tokens generated on-demand** with short expiration
✅ **User authentication required** to generate tokens
✅ **Admin-only config checking** for debugging

## Functions Included

### 1. `generateAgoraToken`
- Generates secure tokens for voice/video calls
- Requires user authentication
- Returns: token, channel name, UID, expiration time

### 2. `checkAgoraConfig` (Admin only)
- Verifies Agora configuration
- Useful for debugging
- Admin-only access

### 3. `cleanupOldCalls`
- Runs daily automatically
- Deletes call records older than 30 days
- Keeps Firestore clean and efficient

## Troubleshooting

### Issue: "Failed to generate token" error

**Solutions:**
1. Check that App Certificate is set:
   ```bash
   firebase functions:config:get
   ```
2. Verify certificate is correct in Agora Console
3. Check function logs:
   ```bash
   firebase functions:log
   ```

### Issue: "Cloud Function not available" warning

**Solutions:**
1. Ensure functions are deployed:
   ```bash
   firebase deploy --only functions
   ```
2. Check Firebase project billing is enabled (required for external HTTP calls)
3. Wait a few minutes after deployment for propagation

### Issue: Token expired error

**Solution**: Tokens are valid for 24 hours by default. The Cloud Function automatically generates fresh tokens on each call.

### Issue: Unable to set config

**Solution**: Make sure you're logged in and have correct project selected:
```bash
firebase login
firebase use --add  # Select your project
firebase functions:config:set agora.app_id="YOUR_ID"
```

## Local Development

### Test Functions Locally

```bash
# Start Firebase emulators
cd functions
npm run serve

# Your local function will run at:
# http://localhost:5001/YOUR_PROJECT_ID/us-central1/generateAgoraToken
```

### Download Config for Local Testing

```bash
# Download production config to local project
firebase functions:config:get > .runtimeconfig.json
```

## Updating Configuration

### Update App Certificate

```bash
# Update certificate
firebase functions:config:set agora.app_certificate="NEW_CERTIFICATE"

# Redeploy functions
firebase deploy --only functions
```

### Update Token Expiration Time

Edit `functions/index.js` and change:
```javascript
const expirationTimeInSeconds = data.expirationTimeInSeconds || 86400; // 24 hours
```

To your preferred duration.

## Advanced: Multiple Regions

Deploy functions to multiple regions for lower latency:

```javascript
// In functions/index.js, add:
exports.generateAgoraTokenEurope = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    // Same implementation
  });
```

## Monitoring

### View Function Activity

1. **Firebase Console**: Functions → Logs
2. **Terminal**: `firebase functions:log`
3. **Real-time**: `firebase functions:log --follow`

### Monitor Agora Usage

1. Go to [Agora Console](https://console.agora.io/)
2. Click on your project
3. Go to **"Usage"** to see call minutes and costs

## Summary

✅ **Token server deployed** - Generates secure tokens on-demand  
✅ **App configured** - Automatically uses Cloud Function  
✅ **Fallbacks in place** - Works in dev mode without server  
✅ **Production ready** - Secure and scalable  
✅ **Cost-effective** - ~$0-5/month for typical usage  

## Next Steps

1. ✅ Test calling feature end-to-end
2. Monitor function logs during testing
3. (Optional) Set up Firebase billing for production use
4. (Optional) Configure custom domain for functions
5. (Optional) Set up monitoring alerts for errors

## Support

- **Firebase Functions**: [Documentation](https://firebase.google.com/docs/functions)
- **Agora Tokens**: [Documentation](https://docs.agora.io/en/video-calling/develop/authentication-workflow)
- **Issues**: Check function logs and Flutter console

---

**Your token server is now set up and ready for production! 🎉**

Need help? Check the troubleshooting section or logs for more details.
