import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription<List<NotificationModel>>? _subscription;
  String? _listeningUserId;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  /// Starts a real Firestore subscription for [uid].
  /// Safe to call repeatedly — re-uses the existing subscription if the uid
  /// hasn't changed.
  void startListening(String uid) {
    if (_listeningUserId == uid && _subscription != null) return;
    stopListening();
    _listeningUserId = uid;
    _subscription = getNotificationsStream(uid).listen((_) {});
  }

  /// Cancels the active Firestore subscription and resets state.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _listeningUserId = null;
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  // Stream of notifications for current user
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
      
      return _notifications;
    });
  }

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        message: message,
        type: type,
        actionUrl: actionUrl,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toMap());
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Send notification to all students enrolled in a course
  Future<void> notifyCourseStudents({
    required String courseId,
    required String title,
    required String message,
    required String type,
    String? actionUrl,
  }) async {
    try {
      // Get all users enrolled in the course
      final users = await _firestore
          .collection('users')
          .where('enrolledCourses', arrayContains: courseId)
          .get();

      final batch = _firestore.batch();
      for (var userDoc in users.docs) {
        final notification = NotificationModel(
          id: '',
          userId: userDoc.id,
          title: title,
          message: message,
          type: type,
          actionUrl: actionUrl,
          metadata: {'courseId': courseId},
          createdAt: DateTime.now(),
        );

        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notification.toMap());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error notifying course students: $e');
    }
  }

  // Send notification to all users with a specific role
  Future<void> notifyByRole({
    required String role,
    required String title,
    required String message,
    required String type,
    String? actionUrl,
  }) async {
    try {
      final users = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      final batch = _firestore.batch();
      for (var userDoc in users.docs) {
        final notification = NotificationModel(
          id: '',
          userId: userDoc.id,
          title: title,
          message: message,
          type: type,
          actionUrl: actionUrl,
          createdAt: DateTime.now(),
        );

        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, notification.toMap());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error notifying users by role: $e');
    }
  }
}
