import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../services/diploma_courses_seeder.dart';

/// Standalone script to seed diploma courses into Firebase Firestore
/// 
/// Run this file to populate your Firestore database with all 20 diploma courses.
/// 
/// Usage (from terminal):
/// flutter run -t lib/utils/seed_diploma_courses.dart
/// 
/// (If you have multiple devices attached, add `-d <deviceId>`)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 Starting Diploma Courses Seeder...\n');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized\n');
  
  final seeder = DiplomaCoursesSeeder();
  
  // Check if courses already exist
  final exists = await seeder.diplomaCoursesExist();
  
  if (exists) {
    print('⚠️  Diploma courses already exist in the database.');
    print('   If you want to re-seed, first clear existing courses.\n');
    print('   Uncomment the clearDiplomaCourses() line in this file.\n');
    
    // Uncomment the line below to clear existing diploma courses before seeding
    // await seeder.clearDiplomaCourses();
    // await seeder.seedDiplomaCourses();
  } else {
    print('📚 Seeding diploma courses...\n');
    await seeder.seedDiplomaCourses();
    print('\n✨ All done! Your diploma courses are now in Firestore.\n');
  }
  
  print('🎓 You can now view the courses in your app!');
}
