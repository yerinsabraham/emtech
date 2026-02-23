import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/forum_post_model.dart';
import 'notification_service.dart';
import 'achievement_service.dart';

class ForumService {
  final _db = FirebaseFirestore.instance;
  final _notificationService = NotificationService();
  CollectionReference get _posts => _db.collection('forumPosts');

  // ── Posts ────────────────────────────────────────────────────────────────────

  /// Stream of all posts, optionally filtered by [category].
  /// Pinned posts are sorted first; then by createdAt desc.
  Stream<List<ForumPostModel>> getPosts({String? category}) {
    Query query = _posts.orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true);

    if (category != null && category != 'all') {
      query = _posts
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) => ForumPostModel.fromMap(
            d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  /// Creates a new forum post. Returns the new document ID.
  Future<String> createPost({
    required String authorId,
    required String authorName,
    required String title,
    required String content,
    required String category,
    List<String> tags = const [],
  }) async {
    try {
      final doc = await _posts.add({
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatarUrl': '',
        'title': title,
        'content': content,
        'category': category,
        'tags': tags,
        'likes': 0,
        'likedBy': [],
        'replies': 0,
        'isPinned': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Notify all students when an announcement is posted
      if (category == 'announcement') {
        await _notificationService.notifyByRole(
          role: 'student',
          title: '\uD83D\uDCE2 New Announcement',
          message: '$authorName posted: "$title"',
          type: 'announcement',
          actionUrl: '/forum/${doc.id}',
        );
      }

      return doc.id;
    } catch (e) {
      debugPrint('ForumService.createPost error: $e');
      rethrow;
    }
  }

  /// Toggles a like for [userId] on [postId].
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      final ref = _posts.doc(postId);
      final snap = await ref.get();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final likedBy = List<String>.from(data['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        await ref.update({
          'likedBy': FieldValue.arrayRemove([userId]),
          'likes': FieldValue.increment(-1),
        });
      } else {
        await ref.update({
          'likedBy': FieldValue.arrayUnion([userId]),
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('ForumService.toggleLike error: $e');
    }
  }

  // ── Replies ──────────────────────────────────────────────────────────────────

  CollectionReference _replies(String postId) =>
      _posts.doc(postId).collection('replies');

  /// Stream of replies for a post, sorted oldest first.
  Stream<List<Map<String, dynamic>>> getReplies(String postId) {
    return _replies(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)})
            .toList());
  }

  /// Adds a reply to [postId] and increments the reply counter.
  Future<void> addReply({
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    try {
      await _replies(postId).add({
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await _posts.doc(postId).update({
        'replies': FieldValue.increment(1),
      });

      // Trigger achievement check for forum reply
      unawaited(AchievementService().onForumReply(authorId));
    } catch (e) {
      debugPrint('ForumService.addReply error: $e');
      rethrow;
    }
  }
}
