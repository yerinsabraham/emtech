import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

/// Script to check and fix admin role
/// Run with: flutter run -t lib/utils/check_and_fix_admin.dart -d macos
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting admin role checker...');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('✅ Firebase initialized');
  
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  
  // Get current user from Firebase Auth
  final currentUser = auth.currentUser;
  
  if (currentUser == null) {
    print('❌ No user is currently logged in');
    print('📝 Please login to the app first, then run this script');
    return;
  }
  
  print('📱 Current Firebase Auth User:');
  print('   UID: ${currentUser.uid}');
  print('   Email: ${currentUser.email}');
  print('   Display Name: ${currentUser.displayName}');
  
  try {
    // Check Firestore user document
    print('\n🔍 Checking Firestore user document...');
    final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
    
    if (!userDoc.exists) {
      print('❌ User document does not exist in Firestore!');
      print('📝 Creating user document...');
      
      await firestore.collection('users').doc(currentUser.uid).set({
        'uid': currentUser.uid,
        'email': currentUser.email,
        'name': currentUser.displayName ?? 'Admin User',
        'role': 'admin',
        'emcBalance': 1000,
        'availableEMC': 1000,
        'totalEMCEarned': 1000,
        'enrolledCourses': [],
        'completedCourses': [],
        'photoUrl': currentUser.photoURL,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ User document created with admin role!');
    } else {
      final userData = userDoc.data()!;
      final currentRole = userData['role'] ?? 'not set';
      
      print('📋 Current Firestore Data:');
      print('   Email: ${userData['email']}');
      print('   Name: ${userData['name']}');
      print('   Role: $currentRole');
      print('   EMC Balance: ${userData['emcBalance']}');
      
      if (currentRole != 'admin') {
        print('\n🔄 Updating role to admin...');
        await firestore.collection('users').doc(currentUser.uid).update({
          'role': 'admin',
          'updatedAt': DateTime.now().toIso8601String(),
        });
        print('✅ Role updated to admin!');
      } else {
        print('✅ User is already an admin!');
      }
    }
    
    // Verify the update
    print('\n🔍 Verifying update...');
    final verifyDoc = await firestore.collection('users').doc(currentUser.uid).get();
    final verifyData = verifyDoc.data()!;
    print('✅ Verified Role: ${verifyData['role']}');
    
    if (verifyData['role'] == 'admin') {
      print('\n🎉 SUCCESS! You are now an admin!');
      print('📝 Go back to your app and do a Hot Restart (press R)');
      print('   Then go to Profile tab to see Admin Dashboard');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n✨ Done! You can close this window.');
}
