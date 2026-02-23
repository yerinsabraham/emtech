# Agora Voice Calling Setup Guide

This guide will help you integrate Agora voice calling functionality into the Emtech School app for customer support.

## Overview

The app now includes:
- **User-side**: Call button in the Support page to call customer service
- **Admin-side**: Incoming call overlay with accept/reject functionality
- **Voice Call Screen**: Full-featured call interface with mute, speaker toggle, and call timer

## Setup Instructions

### 1. Create an Agora Account

1. Go to [https://sso2.agora.io/en/login](https://sso2.agora.io/en/login)
2. Sign up for a free account or log in if you already have one

### 2. Create a New Project

1. After logging in, go to the Agora Console
2. Click on "Project Management" in the left sidebar
3. Click "Create" to create a new project
4. Enter a project name (e.g., "Emtech School Support")
5. Choose "Secured mode: APP ID + Token" for authentication mode (recommended for production)
6. Click "Submit"

### 3. Get Your App ID

1. In your project dashboard, you'll see your **App ID**
2. Copy this App ID - you'll need it in the next step

### 4. Generate a Temporary Token (for Testing)

For testing purposes, you can generate a temporary token:

1. In your Agora project dashboard, go to "Generate temp RTC token"
2. Enter a channel name (e.g., "test_channel")
3. Set the role to "Publisher"
4. Click "Generate"
5. Copy the generated token

**Note**: Temporary tokens expire after 24 hours and are only for testing. For production, you should set up a token server.

### 5. Configure the App

1. Open the file: `lib/config/agora_config.dart`
2. Replace `YOUR_AGORA_APP_ID_HERE` with your actual App ID from step 3
3. (Optional) Replace `YOUR_TEMPORARY_TOKEN_HERE` with your temp token for testing

```dart
class AgoraConfig {
  static const String appId = 'your_actual_app_id_here';
  static const String tempToken = 'your_temp_token_here'; // Optional for testing
  static const String supportChannelPrefix = 'support_call_';
  
  static bool get isConfigured => 
    appId != 'YOUR_AGORA_APP_ID_HERE' && 
    appId.isNotEmpty;
}
```

### 6. Install Dependencies

Run the following command to install all dependencies:

```bash
flutter pub get
```

### 7. Test the Integration

#### For iOS:
```bash
cd ios
pod install
cd ..
flutter run
```

#### For Android:
```bash
flutter run
```

## Production Setup (Token Server)

For production use, you should implement a token server to generate tokens securely. Temporary tokens expire quickly and should not be used in production.

### Why You Need a Token Server

- Tokens generated in the Agora Console expire after 24 hours
- For security, tokens should be generated on-demand by your backend
- The token server validates users and generates appropriate tokens

### Implementing a Token Server

1. **Backend Setup**: Create a server endpoint that generates Agora tokens
   - You can use Node.js, Python, PHP, or any backend language
   - Use Agora's server SDK to generate tokens
   - Example: `https://yourserver.com/api/generate-token`

2. **Modify the Call Service**: Update `lib/services/call_service.dart`
   - Replace the hardcoded token with a dynamic token from your server
   - Make an HTTP request to your token endpoint when joining a call

3. **Reference**: [Agora Token Server Documentation](https://docs.agora.io/en/video-calling/develop/authentication-workflow)

## How It Works

### User Flow (Calling Support)

1. User goes to **Support Page** (via Profile menu)
2. Clicks on **"Call Support"** button
3. App checks if Agora is configured
4. Creates a call document in Firestore with status "ringing"
5. Initiates Agora voice channel
6. Shows call screen with calling status
7. Admin receives incoming call notification

### Admin Flow (Receiving Calls)

1. Admin logs into the app
2. When a user initiates a call, admin sees an incoming call overlay
3. Admin can:
   - **Accept**: Join the voice call
   - **Decline**: Reject the call
4. If accepted, both parties join the same Agora voice channel
5. Call screen shows duration, mute, speaker, and end call options

### Call Features

- **Mute/Unmute**: Toggle microphone on/off
- **Speaker**: Toggle speakerphone
- **Call Timer**: Shows call duration
- **End Call**: Terminates the call and updates Firestore
- **Call History**: All calls are logged in Firestore

## Database Structure

Calls are stored in Firestore under the `calls` collection:

```javascript
{
  callId: "auto_generated_id",
  callerId: "user_uid",
  callerName: "User Name",
  callerPhotoUrl: "optional_photo_url",
  receiverId: "admin_uid",
  channelName: "support_call_timestamp",
  status: "ringing" | "answered" | "ended" | "missed" | "rejected",
  createdAt: Timestamp,
  answeredAt: Timestamp (optional),
  endedAt: Timestamp (optional),
  duration: number (seconds, optional)
}
```

## Firestore Security Rules

Add these rules to your Firestore to secure the calls collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Calls collection
    match /calls/{callId} {
      // Users can create calls
      allow create: if request.auth != null;
      
      // Users can read their own calls (as caller or receiver)
      allow read: if request.auth != null && (
        resource.data.callerId == request.auth.uid ||
        resource.data.receiverId == request.auth.uid
      );
      
      // Users can update their own calls
      allow update: if request.auth != null && (
        resource.data.callerId == request.auth.uid ||
        resource.data.receiverId == request.auth.uid
      );
    }
  }
}
```

## Troubleshooting

### Issue: "Agora not configured" message appears

**Solution**: Make sure you've replaced `YOUR_AGORA_APP_ID_HERE` in `lib/config/agora_config.dart` with your actual App ID.

### Issue: Cannot hear the other party

**Solution**: 
- Check microphone permissions are granted
- Ensure speaker/audio output is working
- Try toggling the speaker button in the call screen

### Issue: Call connects but no admin receives it

**Solution**: 
- Ensure at least one user has the role "admin" in Firestore
- Check that the admin is logged into the app
- Verify Firestore permissions allow reading/writing to the calls collection

### Issue: "Failed to join channel" error

**Solution**:
- If using temporary tokens, make sure they haven't expired
- Verify your App ID is correct
- Check internet connectivity
- For production, ensure your token server is working properly

## Testing Tips

1. **Two Devices**: Test with two physical devices or one device + simulator
2. **Admin Account**: Ensure you have an admin account for testing
   - Set a user's role to "admin" in Firestore
3. **Check Firestore**: Monitor the `calls` collection during testing
4. **Console Logs**: Check Flutter console for Agora connection logs

## Features Implemented

✅ Voice calling from Support page  
✅ Incoming call overlay for admins  
✅ Mute/unmute functionality  
✅ Speaker toggle  
✅ Call timer  
✅ Call status tracking (ringing, answered, ended, etc.)  
✅ Call history in Firestore  
✅ Permission handling for microphone  
✅ Graceful error handling  

## Cost Considerations

- **Free Tier**: Agora provides 10,000 free minutes per month
- **Pricing**: After free tier, pricing varies by region and usage
- **Monitor Usage**: Check your Agora console regularly to monitor usage

## Support Resources

- [Agora Documentation](https://docs.agora.io/)
- [Agora Flutter SDK Guide](https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter)
- [Agora Community](https://www.agora.io/en/community/)

## Next Steps

Once you've configured Agora with your API keys:

1. Test the calling feature with a user and admin account
2. Monitor call logs in Firestore
3. Set up a token server for production (instead of using temporary tokens)
4. (Optional) Add call history UI in the app
5. (Optional) Add push notifications for incoming calls when app is in background

---

**Note**: Remember to never commit your Agora App ID or tokens to public repositories. Consider using environment variables or secure configuration management for production apps.
