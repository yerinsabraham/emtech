## Authentication Test Checklist

### ✅ Completed Steps
- [x] Email/Password authentication enabled in Firebase Console
- [x] Google Sign-In enabled in Firebase Console  
- [x] Support email set (elitekigali76@gmail.com)
- [x] Auth service code configured

### 🔧 Required Steps (Complete These Now)

#### Add SHA-1 Fingerprint to Firebase
- [ ] Go to [Firebase Project Settings](https://console.firebase.google.com/project/emtech-be4d4/settings/general)
- [ ] Scroll to "Your apps" section
- [ ] Find Android app: `com.emtech.emtech_school`
- [ ] Click "Add fingerprint"
- [ ] Paste SHA-1: `7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2`
- [ ] Click "Save"
- [ ] **Download the NEW google-services.json file**
- [ ] Replace `android/app/google-services.json` with the downloaded file

### 🧪 Testing Commands

After completing the steps above, run:

```powershell
# Clean the build
flutter clean

# Get dependencies
flutter pub get

# Clean Android build
cd android
./gradlew clean
cd ..

# Run the app
flutter run
```

### 🧪 Test Scenarios

#### Test 1: Email/Password Sign Up
1. Open the app
2. Go to Login/Sign Up page
3. Switch to "Sign Up" mode
4. Enter:
   - Name: Test User
   - Email: test@example.com
   - Password: Test123!
5. Click Sign Up
6. ✅ Should create account and log in successfully
7. Check Firebase Console → Authentication → Users (should see new user)

#### Test 2: Email/Password Sign In
1. Sign out if logged in
2. Go to Login page
3. Enter credentials from Test 1
4. Click Sign In
5. ✅ Should log in successfully

#### Test 3: Google Sign-In
1. Sign out if logged in
2. Go to Login page
3. Click "Sign in with Google" button
4. Select your Google account
5. ✅ Should log in successfully
6. Check Firebase Console → Authentication → Users (should see Google user)

### 🐛 Troubleshooting

#### Google Sign-In Issues

**Error: "Developer Error" or "Sign-in failed"**
- ❌ SHA-1 not added to Firebase
- ❌ google-services.json not updated
- ✅ Add SHA-1 and download new google-services.json

**Error: "ApiException: 10"**  
- ❌ Package name mismatch
- ❌ SHA-1 not registered correctly
- ✅ Verify package name: `com.emtech.emtech_school`
- ✅ Re-check SHA-1 fingerprint

**Error: "PlatformException: sign_in_failed"**
- ❌ OAuth client not properly configured
- ✅ Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials?project=emtech-be4d4)
- ✅ Verify Android OAuth client has correct SHA-1

#### Email/Password Issues

**Error: "The email address is badly formatted"**
- ✅ Check email format (must be valid email)

**Error: "The password is too weak"**
- ✅ Password must be at least 6 characters

**Error: "The email address is already in use"**
- ✅ User already exists, try signing in instead

**Error: "There is no user record"**
- ✅ User doesn't exist, sign up first

### 📊 Verification

After successful authentication:
- User should be logged in
- User profile should load
- EMC balance should show 1000 (sign-up bonus)
- Check Firebase Console → Authentication → Users to see registered users
- Check Firebase Console → Firestore → users collection to see user data

### 🎉 Success Indicators

- ✅ No errors during authentication
- ✅ User data loads in the app
- ✅ User appears in Firebase Authentication console
- ✅ User document created in Firestore
- ✅ Can sign out and sign back in
- ✅ Can switch between Email/Password and Google accounts

### 📝 Current Status

**SHA-1 Fingerprint:** `7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2`

**What's Working:**
- ✅ Firebase project connected
- ✅ Authentication providers enabled
- ✅ Auth service code ready

**What Needs Completion:**
- ⏳ Add SHA-1 to Firebase Console (Required for Google Sign-In)
- ⏳ Download and replace google-services.json
- ⏳ Clean build and test

Once you complete the SHA-1 setup, authentication should work perfectly! 🚀
