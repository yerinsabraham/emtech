import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Handles FCM token registration, permission requests, and push delivery via
/// Firestore-triggered Cloud Functions (or direct API if needed).
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Call once after Firebase.initializeApp. Requests permission, fetches the
  /// FCM token, stores it in the current user's Firestore doc, and wires up
  /// foreground message handling.
  static Future<void> initialize() async {
    // Request permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Store token
    await _saveToken();

    // Token refresh listener
    FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  static Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('PushNotificationService._saveToken error: $e');
    }
  }

  static Future<void> _onTokenRefresh(String token) async {
    await _saveToken();
  }

  static void _onForegroundMessage(RemoteMessage message) {
    debugPrint(
        'FCM foreground: ${message.notification?.title} — ${message.notification?.body}');
    // In-app notification overlay is handled by NotificationService streams.
  }

  /// Call after user logs out to remove the FCM token from Firestore.
  static Future<void> removeToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await _db.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('PushNotificationService.removeToken error: $e');
    }
  }

  /// Reads all FCM tokens for [userId] and writes a push request document that
  /// a Cloud Function (or your own backend) can process. The document is placed
  /// in `pushRequests/{uid}` so it can be fanned-out server-side.
  static Future<void> sendPushToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _db.collection('pushRequests').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('PushNotificationService.sendPushToUser error: $e');
    }
  }

  /// Broadcasts a push to all users with a given role by writing a broadcast
  /// document. A Cloud Function should fan this out to per-user tokens.
  static Future<void> broadcastToRole({
    required String role,
    required String title,
    required String body,
  }) async {
    try {
      await _db.collection('pushBroadcasts').add({
        'role': role,
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('PushNotificationService.broadcastToRole error: $e');
    }
  }
}
