class BlogPostModel {
  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String author;
  final String category; // 'news', 'tutorial', 'announcement'
  final String? imageUrl;
  final DateTime publishedAt;
  final int readTimeMinutes;
  final List<String> tags;

  BlogPostModel({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.author,
    required this.category,
    this.imageUrl,
    required this.publishedAt,
    this.readTimeMinutes = 5,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'author': author,
      'category': category,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'readTimeMinutes': readTimeMinutes,
      'tags': tags,
    };
  }

  factory BlogPostModel.fromMap(Map<String, dynamic> map, String id) {
    return BlogPostModel(
      id: id,
      title: map['title'] ?? '',
      excerpt: map['excerpt'] ?? '',
      content: map['content'] ?? '',
      author: map['author'] ?? '',
      category: map['category'] ?? 'news',
      imageUrl: map['imageUrl'],
      publishedAt: DateTime.parse(map['publishedAt']),
      readTimeMinutes: map['readTimeMinutes'] ?? 5,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}
