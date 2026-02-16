class ForumPostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatarUrl;
  final String title;
  final String content;
  final String category; // 'question', 'discussion', 'announcement'
  final int likes;
  final int replies;
  final DateTime createdAt;
  final List<String> tags;
  final bool isPinned;

  ForumPostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl = '',
    required this.title,
    required this.content,
    required this.category,
    this.likes = 0,
    this.replies = 0,
    required this.createdAt,
    this.tags = const [],
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'title': title,
      'content': content,
      'category': category,
      'likes': likes,
      'replies': replies,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'isPinned': isPinned,
    };
  }

  factory ForumPostModel.fromMap(Map<String, dynamic> map, String id) {
    return ForumPostModel(
      id: id,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatarUrl: map['authorAvatarUrl'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'discussion',
      likes: map['likes'] ?? 0,
      replies: map['replies'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      tags: List<String>.from(map['tags'] ?? []),
      isPinned: map['isPinned'] ?? false,
    );
  }
}
