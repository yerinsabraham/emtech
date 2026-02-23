import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  User? _user;
  UserModel? _userModel;
  bool _isLoadingUserData = false;

  User? get user => _user;
  User? get currentUser => _user;
  UserModel? get userModel => _userModel;
  bool get isAuthenticated => _user != null;
  bool get isLoadingUserData => _isLoadingUserData;

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        _isLoadingUserData = true;
        notifyListeners();
        await _loadUserData(user.uid);
        _isLoadingUserData = false;
      } else {
        _userModel = null;
        _isLoadingUserData = false;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!, uid);
        debugPrint('✅ User data loaded - Role: ${_userModel?.role}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Public method to force reload user data
  Future<void> reloadUserData() async {
    if (_user != null) {
      await _loadUserData(_user!.uid);
    }
  }

  // Sign up with email and password
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'student', // Default to student for public signup
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final newUser = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          role: role,
          emcBalance: 1000, // Sign-up reward: 1000 EMC
          availableEMC: 1000,
          totalEMCEarned: 1000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toMap());

        // Record the signup reward transaction
        await _firestore.collection('transactions').add({
          'userId': credential.user!.uid,
          'type': 'earn',
          'amount': 1000,
          'description': 'Welcome Bonus - Sign-up Reward',
          'relatedId': 'signup_reward',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        // Create a reward record
        await _firestore.collection('rewards').add({
          'userId': credential.user!.uid,
          'type': 'signup',
          'amount': 1000.0,
          'redeemed': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'redeemedAt': Timestamp.fromDate(DateTime.now()),
        });

        _userModel = newUser;
        notifyListeners();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during sign up';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during sign in';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return 'Sign in cancelled';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user document exists, if not create one
      if (userCredential.user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!doc.exists) {
          // Create new user document for first-time Google sign-in
          final newUser = UserModel(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'Student',
            emcBalance: 1000, // Sign-up reward: 1000 EMC
            availableEMC: 1000,
            totalEMCEarned: 1000,
            photoUrl: userCredential.user!.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUser.toMap());

          // Record the signup reward transaction
          await _firestore.collection('transactions').add({
            'userId': userCredential.user!.uid,
            'type': 'earn',
            'amount': 1000,
            'description': 'Welcome Bonus - Google Sign-in Reward',
            'relatedId': 'signup_reward',
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });

          // Create a reward record
          await _firestore.collection('rewards').add({
            'userId': userCredential.user!.uid,
            'type': 'signup',
            'amount': 1000.0,
            'redeemed': true,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'redeemedAt': Timestamp.fromDate(DateTime.now()),
          });

          _userModel = newUser;
        } else {
          _userModel = UserModel.fromMap(doc.data()!, userCredential.user!.uid);
        }
        notifyListeners();
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred during Google sign in';
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return 'An unexpected error occurred';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _userModel = null;
    notifyListeners();
  }

  // Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? session,
    String? photoUrl,
  }) async {
    if (_user == null || _userModel == null) return;

    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (session != null) updates['session'] = session;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(_user!.uid).update(updates);

      _userModel = _userModel!.copyWith(
        name: name ?? _userModel!.name,
        session: session ?? _userModel!.session,
        photoUrl: photoUrl ?? _userModel!.photoUrl,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  // Add EMC tokens
  Future<void> addEmcTokens(int amount, String description) async {
    if (_user == null || _userModel == null) return;

    try {
      final newBalance = _userModel!.emcBalance + amount;

      await _firestore.collection('users').doc(_user!.uid).update({
        'emcBalance': newBalance,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _userModel = _userModel!.copyWith(
        emcBalance: newBalance,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding EMC tokens: $e');
    }
  }

  // Spend EMC tokens
  Future<bool> spendEmcTokens(int amount, String description) async {
    if (_user == null || _userModel == null) return false;
    if (_userModel!.emcBalance < amount) return false;

    try {
      final newBalance = _userModel!.emcBalance - amount;

      await _firestore.collection('users').doc(_user!.uid).update({
        'emcBalance': newBalance,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _userModel = _userModel!.copyWith(
        emcBalance: newBalance,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error spending EMC tokens: $e');
      return false;
    }
  }

  // ────────────────────────────────────────────
  // ROLE MANAGEMENT
  // ────────────────────────────────────────────

  // Check if current user is admin
  bool get isAdmin => _userModel?.role == 'admin';

  // Check if current user is lecturer
  bool get isLecturer => _userModel?.role == 'lecturer';

  // Check if current user is student
  bool get isStudent => _userModel?.role == 'student';

  // Get user role
  String get userRole => _userModel?.role ?? 'student';

  // Create lecturer account (Admin only)
  Future<String?> createLecturerAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    // Only admins can create lecturer accounts
    if (!isAdmin) {
      return 'Only administrators can create lecturer accounts';
    }

    try {
      // Use secondary Firebase Auth instance to avoid signing out current admin
      final tempAuth = FirebaseAuth.instance;
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final newLecturer = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          role: 'lecturer',
          emcBalance: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newLecturer.toMap());

        // Sign out the temporary user
        await tempAuth.signOut();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An error occurred creating lecturer account';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Update user role (Admin only)
  Future<String?> updateUserRole(String userId, String newRole) async {
    if (!isAdmin) {
      return 'Only administrators can update user roles';
    }

    if (!['student', 'lecturer', 'admin'].contains(newRole)) {
      return 'Invalid role. Must be student, lecturer, or admin';
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Reload user data if updating current user
      if (userId == _user?.uid) {
        await _loadUserData(userId);
      }

      return null;
    } catch (e) {
      debugPrint('Error updating user role: $e');
      return 'An error occurred updating role';
    }
  }
}
