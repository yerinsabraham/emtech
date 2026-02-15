class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final int priceEmc;
  final String category; // Textbooks, Novels, Reference
  final String? coverImageUrl;
  final DateTime createdAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.priceEmc,
    required this.category,
    this.coverImageUrl,
    required this.createdAt,
  });

  factory BookModel.fromMap(Map<String, dynamic> map, String id) {
    return BookModel(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      description: map['description'] ?? '',
      priceEmc: map['priceEmc'] ?? 0,
      category: map['category'] ?? 'Textbooks',
      coverImageUrl: map['coverImageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'priceEmc': priceEmc,
      'category': category,
      'coverImageUrl': coverImageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
