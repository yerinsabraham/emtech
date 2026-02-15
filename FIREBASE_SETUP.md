# Firebase Configuration Setup Guide

## 🔐 Security Notice

This project uses Firebase for backend services. The Firebase configuration files contain API keys and project identifiers that should **NOT** be committed to version control.

## 📋 Required Configuration Files

The following files are gitignored and must be set up locally:

1. `lib/firebase_options.dart`
2. `android/app/google-services.json`
3. `ios/Runner/GoogleService-Info.plist`
4. `macos/Runner/GoogleService-Info.plist`

## 🚀 Setup Instructions

### Option 1: Using FlutterFire CLI (Recommended)

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Configure your project:
   ```bash
   flutterfire configure
   ```
   
   This will:
   - Create/update `lib/firebase_options.dart`
   - Download configuration files for each platform
   - Set up your Firebase project connection

### Option 2: Manual Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `emtech-be4d4`
3. Download configuration files for each platform:

#### For Android:
- Go to Project Settings → Your Apps → Android app
- Download `google-services.json`
- Place it in `android/app/google-services.json`

#### For iOS/macOS:
- Go to Project Settings → Your Apps → iOS app
- Download `GoogleService-Info.plist`
- Place it in `ios/Runner/GoogleService-Info.plist`
- Copy to `macos/Runner/GoogleService-Info.plist`

#### For Web/Windows:
- Copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart`
- Fill in your Firebase project credentials

## 🔒 Security Best Practices

### Firebase API Keys - Important Context

**Note**: Firebase API keys in client apps are not secret keys. They:
- Identify your Firebase project
- Are safe to include in client-side code
- Don't grant access by themselves

**Real security comes from**:
1. Firebase Security Rules (Firestore, Storage, RTDB)
2. App Check for abuse prevention
3. Proper authentication implementation

### Current Security Measures

✅ Configuration files are gitignored
✅ Template files provided for reference
✅ Setup documentation included

### Recommended: Firebase Security Rules

Ensure your Firestore and Storage have proper security rules:

```javascript
// Example Firestore rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## ⚠️ If Keys Were Exposed

If you believe your Firebase configuration was exposed in a public repository:

1. **Rotate API Keys** (if possible through Firebase Console)
2. **Review Firebase Security Rules** - ensure they're restrictive
3. **Enable App Check** - prevents API abuse
4. **Monitor Usage** - check Firebase Console for unexpected activity
5. **Consider enabling Firebase App Check** for additional security

## 🔗 Useful Links

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Firebase App Check](https://firebase.google.com/docs/app-check)

## 📝 For Team Members

When cloning this repository:
1. Follow the setup instructions above
2. Never commit the actual configuration files
3. Use the `.example` files as templates
4. Keep your local `firebase_options.dart` updated with your development project
