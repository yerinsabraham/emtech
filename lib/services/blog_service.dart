import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/blog_post_model.dart';
import 'notification_service.dart';

class BlogService {
  final _db = FirebaseFirestore.instance;
  final _notificationService = NotificationService();
  CollectionReference get _col => _db.collection('blogPosts');

  /// Stream of published blog posts, optionally filtered by [category].
  /// Sorted by publishedAt descending.
  Stream<List<BlogPostModel>> getBlogPosts({String? category}) {
    Query query = _col.orderBy('publishedAt', descending: true);

    if (category != null && category != 'all') {
      query = _col
          .where('category', isEqualTo: category)
          .orderBy('publishedAt', descending: true);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) =>
            BlogPostModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  /// Fetches a single blog post by [postId].
  Future<BlogPostModel?> getPost(String postId) async {
    try {
      final doc = await _col.doc(postId).get();
      if (!doc.exists) return null;
      return BlogPostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      debugPrint('BlogService.getPost error: $e');
      return null;
    }
  }

  /// Admin: create a new blog post.
  Future<String> createPost(BlogPostModel post) async {
    final doc = await _col.add({
      ...post.toMap(),
      'publishedAt': post.publishedAt.toIso8601String(),
    });

    // Notify all students of new content
    final icon = post.category == 'announcement' ? '\uD83D\uDCE2' : '\uD83D\uDCDD';
    await _notificationService.notifyByRole(
      role: 'student',
      title: '$icon New ${_categoryLabel(post.category)}',
      message: post.title,
      type: 'blog',
      actionUrl: '/blog/${doc.id}',
    );

    return doc.id;
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'announcement': return 'Announcement';
      case 'tutorial': return 'Tutorial';
      default: return 'Article';
    }
  }
}
