# Quick Setup Guide

## ✅ Fixes Applied

### 1. Google Sign-In URL Scheme (CRITICAL FIX)
- **Issue**: App crashed with "missing support for URL schemes" error
- **Fix**: Added Google Sign-In URL scheme to `ios/Runner/Info.plist`
- **Status**: ✅ Fixed

### 2. Firestore Security Rules Updated
- **Issue**: Permission denied when writing to books/courses collections
- **Fix**: Updated `firestore.rules` with role-based access control
- **Status**: ✅ Deployed to Firebase

## 🔐 Making Yourself an Admin

Since the seed data requires admin privileges, follow these steps:

### Method 1: Firebase Console (Recommended)

1. **Sign in to your app** with Google (it will work now!)
2. Go to [Firebase Console](https://console.firebase.google.com/project/emtech-be4d4/firestore)
3. Navigate to **Firestore Database**
4. Find the **users** collection
5. Find your user document (search by your email)
6. Click on your document
7. Find the `role` field and change it from `student` to `admin`
8. Restart the app

### Method 2: Using Firebase CLI

```bash
# Install Firebase tools if not already installed
npm install -g firebase-tools

# Login
firebase login

# Use Firebase console to update - safer than scripts
```

## 📱 Testing the Fix

1. **Stop the current app** (if running)
2. **Clean build**:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```
4. **Sign in with Google** - should work without crashing!
5. **If you're an admin**: Sample data will be seeded automatically

## 🔍 What Changed

### Files Modified:
- `ios/Runner/Info.plist` - Added Google OAuth URL scheme
- `firestore.rules` - Updated with comprehensive security rules
- Deployed rules to Firebase

### Security Rules Summary:
- **Books**: Admins only (read: public)
- **Courses**: Lecturers & Admins (read: public)
- **Users**: Self-read/write only
- **Transactions**: Self-read, self-create
- **Stakes**: Self-manage
- **Rewards**: Self-read, system-create
- **Content**: Lecturers & Admins
- **Loans**: Self-manage, admin-approve

## 🚨 If Still Having Issues

### Google Sign-In Still Crashes:
1. Ensure you've stopped and restarted the app
2. Try `flutter clean` then rebuild
3. Check iOS simulator is not caching old build

### Firestore Permission Errors:
1. Verify you've set your role to `admin` in Firestore
2. Sign out and sign in again to refresh permissions
3. Check Firebase Console for rule deployment status

## 📧 Need Help?

Check the logs with:
```bash
flutter run 2>&1 | tee logs.txt
```

Then share `logs.txt` for debugging.
