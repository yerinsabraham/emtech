import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

/// Quick utility to make a user admin
/// Run with: flutter run -t lib/utils/make_admin.dart -d macos
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting admin updater...');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('✅ Firebase initialized');
  
  // !!! CHANGE THIS TO YOUR EMAIL !!!
  const String emailToMakeAdmin = 'yerinssaibs@gmail.com';
  
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Find user by email
    print('🔍 Looking for user: $emailToMakeAdmin');
    final querySnapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: emailToMakeAdmin)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      print('❌ User not found. Make sure you\'ve signed up first!');
      return;
    }
    
    final userDoc = querySnapshot.docs.first;
    final currentRole = userDoc.data()['role'];
    
    print('📋 Current role: $currentRole');
    
    if (currentRole == 'admin') {
      print('✅ User is already an admin!');
      return;
    }
    
    // Update to admin
    print('🔄 Updating role to admin...');
    await userDoc.reference.update({
      'role': 'admin',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    
    print('✅ Successfully updated $emailToMakeAdmin to admin!');
    print('🎉 You can now access the Admin Panel');
    
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('✨ Done! Press Ctrl+C or close this window.');
}
