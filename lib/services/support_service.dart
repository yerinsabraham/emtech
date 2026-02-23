import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class SupportService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('supportTickets');

  static const String supportEmail = 'support@emtech.com';

  /// Creates a support ticket and notifies all admins in-app.
  /// Returns the new ticket document ID.
  Future<String> createTicket({
    required String userId,
    required String userName,
    required String email,
    required String category,
    required String message,
  }) async {
    try {
      final doc = await _col.add({
        'userId': userId,
        'userName': userName,
        'email': email,
        'category': category,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify all admin users in-app
      await NotificationService().notifyByRole(
        role: 'admin',
        title: 'New Support Ticket',
        message: '$userName submitted a "$category" ticket',
        type: 'support',
        actionUrl: 'support_tickets/${doc.id}',
      );

      return doc.id;
    } catch (e) {
      debugPrint('SupportService.createTicket error: $e');
      rethrow;
    }
  }

  /// Stream of tickets for a specific user.
  Stream<List<Map<String, dynamic>>> getUserTickets(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
            .toList());
  }

  /// Admin: stream all open tickets.
  Stream<List<Map<String, dynamic>>> getAllOpenTickets() {
    return _col
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
            .toList());
  }

  /// Close a ticket (admin action).
  Future<void> closeTicket(String ticketId) async {
    await _col.doc(ticketId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
