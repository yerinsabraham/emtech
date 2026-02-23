#!/usr/bin/env node

/**
 * Firebase Authentication Configuration Helper
 * 
 * This script helps verify and guide you through setting up
 * Firebase Authentication for Google Sign-In and Email/Password.
 */

console.log('\n╔═══════════════════════════════════════════════════════════════════╗');
console.log('║     Firebase Authentication Configuration Helper                  ║');
console.log('╚═══════════════════════════════════════════════════════════════════╝\n');

console.log('📋 Project Information:');
console.log('   Project ID: emtech-be4d4');
console.log('   Package Name: com.emtech.emtech_school');
console.log('   SHA-1: 7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2\n');

console.log('🔧 REQUIRED MANUAL STEPS IN FIREBASE CONSOLE:\n');

console.log('═══════════════════════════════════════════════════════════════════');
console.log('STEP 1: Add SHA-1 Fingerprint');
console.log('═══════════════════════════════════════════════════════════════════');
console.log('1. Open: https://console.firebase.google.com/project/emtech-be4d4/settings/general');
console.log('2. Scroll to "Your apps" section');
console.log('3. Find: com.emtech.emtech_school (Android app)');
console.log('4. Click "Add fingerprint"');
console.log('5. Paste SHA-1: 7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2');
console.log('6. Click "Save"');
console.log('7. ⚠️  CRITICAL: Download the NEW google-services.json file');
console.log('8. Replace: android/app/google-services.json with the downloaded file\n');

console.log('═══════════════════════════════════════════════════════════════════');
console.log('STEP 2: Enable Email/Password Authentication');
console.log('═══════════════════════════════════════════════════════════════════');
console.log('1. Open: https://console.firebase.google.com/project/emtech-be4d4/authentication/providers');
console.log('2. Click "Get Started" if first time');
console.log('3. Click on "Email/Password" provider');
console.log('4. Toggle "Enable" to ON');
console.log('5. Click "Save"\n');

console.log('═══════════════════════════════════════════════════════════════════');
console.log('STEP 3: Enable Google Sign-In');
console.log('═══════════════════════════════════════════════════════════════════');
console.log('1. In same "Sign-in method" tab');
console.log('2. Click on "Google" provider');
console.log('3. Toggle "Enable" to ON');
console.log('4. Set Support email: elitekigali76@gmail.com');
console.log('5. Click "Save"');
console.log('6. 📝 Note: Copy the Web client ID shown (you\'ll verify it later)\n');

console.log('═══════════════════════════════════════════════════════════════════');
console.log('STEP 4: Verify OAuth Configuration');
console.log('═══════════════════════════════════════════════════════════════════');
console.log('1. Open: https://console.cloud.google.com/apis/credentials?project=emtech-be4d4');
console.log('2. Look for OAuth 2.0 Client IDs:');
console.log('   - Web client (auto-created by Google Service)');
console.log('   - Android client');
console.log('3. Click on Android client:');
console.log('   - Package name: com.emtech.emtech_school');
console.log('   - SHA-1: 7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2');
console.log('4. If Android client missing, create new OAuth client ID:');
console.log('   - Type: Android');
console.log('   - Name: Android client for emtech_school');
console.log('   - Package: com.emtech.emtech_school');
console.log('   - SHA-1: 7D:43:D3:53:A9:FC:F1:04:39:6C:5F:22:9F:01:95:2E:B6:C8:08:A2\n');

console.log('═══════════════════════════════════════════════════════════════════');
console.log('STEP 5: Update google-services.json and Test');
console.log('═══════════════════════════════════════════════════════════════════');
console.log('After completing above steps, run these commands:\n');
console.log('   flutter clean');
console.log('   flutter pub get');
console.log('   cd android && ./gradlew clean && cd ..');
console.log('   flutter run\n');

console.log('═══════════════════════════════════════════════════════════════════');
console.log('VERIFICATION CHECKLIST');
console.log('═══════════════════════════════════════════════════════════════════');
console.log('Before testing, ensure:');
console.log('[ ] SHA-1 added to Firebase Console');
console.log('[ ] New google-services.json downloaded and replaced');
console.log('[ ] Email/Password auth enabled in Firebase');
console.log('[ ] Google Sign-In enabled in Firebase');
console.log('[ ] Support email set for Google Sign-In');
console.log('[ ] OAuth Android client configured in Google Cloud Console');
console.log('[ ] Package name matches: com.emtech.emtech_school');
console.log('[ ] Flutter clean and rebuild completed\n');

console.log('═══════════════════════════════════════════════════════════════════');
console.log('COMMON ISSUES & SOLUTIONS');
console.log('═══════════════════════════════════════════════════════════════════');
console.log('❌ "Developer Error" or "Sign-in failed"');
console.log('   ➜ SHA-1 not added or google-services.json not updated\n');
console.log('❌ "ApiException: 10"');
console.log('   ➜ Package name mismatch or SHA-1 incorrect\n');
console.log('❌ "PlatformException: sign_in_failed"');
console.log('   ➜ OAuth client not configured properly\n');
console.log('❌ Email/Password not working');
console.log('   ➜ Check Email/Password provider is enabled in Firebase Console\n');

console.log('═══════════════════════════════════════════════════════════════════');
console.log('QUICK LINKS');
console.log('═══════════════════════════════════════════════════════════════════');
console.log('Firebase Console: https://console.firebase.google.com/project/emtech-be4d4');
console.log('Authentication: https://console.firebase.google.com/project/emtech-be4d4/authentication');
console.log('Project Settings: https://console.firebase.google.com/project/emtech-be4d4/settings/general');
console.log('Google Cloud Console: https://console.cloud.google.com/apis/credentials?project=emtech-be4d4');
console.log('\n');

// Check if running from correct directory
const fs = require('fs');
const path = require('path');

// Try to find google-services.json from project root
const scriptDir = __dirname;
const projectRoot = path.join(scriptDir, '..');
const googleServicesPath = path.join(projectRoot, 'android', 'app', 'google-services.json');
if (fs.existsSync(googleServicesPath)) {
  console.log('✅ google-services.json found at: android/app/google-services.json');
  
  try {
    const content = JSON.parse(fs.readFileSync(googleServicesPath, 'utf8'));
    const projectId = content.project_info?.project_id;
    const packageName = content.client?.[0]?.client_info?.android_client_info?.package_name;
    
    console.log('\n📱 Current Configuration:');
    console.log(`   Project ID: ${projectId}`);
    console.log(`   Package Name: ${packageName}`);
    
    // Check for OAuth clients
    const oauthClients = content.client?.[0]?.oauth_client || [];
    console.log(`   OAuth Clients: ${oauthClients.length} configured`);
    
    if (oauthClients.length === 0) {
      console.log('\n⚠️  WARNING: No OAuth clients found in google-services.json');
      console.log('   This is expected if SHA-1 hasn\'t been added yet.');
      console.log('   After adding SHA-1 in Firebase Console, download the NEW file.');
    }
    
    // Check for web client
    const webClient = content.client?.[0]?.services?.appinvite_service?.other_platform_oauth_client;
    if (webClient && webClient.length > 0) {
      console.log(`\n🌐 Web OAuth Client ID found:`);
      console.log(`   ${webClient[0].client_id}`);
    } else {
      console.log('\n⚠️  WARNING: Web OAuth client not found');
      console.log('   Enable Google Sign-In in Firebase Console to generate this.');
    }
    
  } catch (e) {
    console.log('⚠️  Could not parse google-services.json');
  }
} else {
  console.log('❌ google-services.json NOT found!');
  console.log('   Expected location: android/app/google-services.json');
}

console.log('\n═══════════════════════════════════════════════════════════════════');
console.log('Next Steps:');
console.log('═══════════════════════════════════════════════════════════════════');
console.log('1. Complete ALL manual steps above in Firebase Console');
console.log('2. Download the updated google-services.json');
console.log('3. Replace android/app/google-services.json');
console.log('4. Run: flutter clean && flutter pub get');
console.log('5. Run: flutter run');
console.log('6. Test both Email/Password and Google Sign-In\n');

console.log('💡 See AUTHENTICATION_SETUP_GUIDE.md for detailed instructions\n');
