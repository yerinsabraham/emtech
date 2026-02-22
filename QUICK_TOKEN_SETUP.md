# 🚀 Quick Setup: Agora Token Server

Your token server is ready to deploy! Follow these simple steps:

## 📋 Prerequisites Checklist

- ✅ Agora App ID: `6994ddd5b9674386b5602fb67fbb2c9e`
- ⬜ Agora App Certificate (get from step 1)
- ✅ Firebase account logged in
- ⬜ Node.js installed

## 🚀 Quick Setup (5 minutes)

### 1️⃣ Get Your App Certificate

Visit [Agora Console](https://console.agora.io/):
1. Go to your project → Config
2. Enable "App Certificate" if not enabled
3. **Copy the certificate** (you'll need it next)

### 2️⃣ Install & Configure

```bash
# Install dependencies
cd functions
npm install
cd ..

# Set your Agora credentials
firebase functions:config:set agora.app_id="6994ddd5b9674386b5602fb67fbb2c9e"
firebase functions:config:set agora.app_certificate="PASTE_YOUR_CERTIFICATE_HERE"

# Verify configuration
firebase functions:config:get
```

### 3️⃣ Deploy to Firebase

```bash
# Deploy the token server
firebase deploy --only functions

# Wait 2-3 minutes for deployment
```

### 4️⃣ Update Flutter App

```bash
# Install new dependencies
flutter pub get

# For iOS
cd ios && pod install && cd ..

# Run the app
flutter run
```

## ✅ Test It Works

1. **Make a test call**: Profile → Support → "Call Support"
2. **Check logs**: Should see `✅ Token generated from Cloud Function`
3. **Call works**: You can talk to admin!

## 🎉 You're Done!

Your production-ready token server is live! Tokens are now:
- ✅ Generated securely on-demand
- ✅ Never exposed in client code
- ✅ Automatically expire after 24 hours
- ✅ Free tier: ~$0/month for typical usage

## 📚 Full Documentation

- **Complete Setup**: See `AGORA_TOKEN_SERVER_SETUP.md`
- **Troubleshooting**: Check the guide if something goes wrong
- **Firebase Functions**: `functions/README.md`

## 🆘 Quick Troubleshooting

**Problem**: "Cloud Function not available" warning

**Solution**: 
1. Check functions deployed: `firebase functions:list`
2. Enable billing in Firebase Console (required for external calls)
3. Wait 2-3 minutes after deployment

**Problem**: "Failed to generate token"

**Solution**:
1. Verify certificate: `firebase functions:config:get`
2. Check it matches Agora Console certificate
3. View logs: `firebase functions:log`

---

**Status**: 🟢 Ready to deploy!

Just run the commands above and you're good to go! 🎊
