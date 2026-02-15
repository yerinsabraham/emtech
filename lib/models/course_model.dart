class CourseModel {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final int priceEmc;
  final String category; // Freemium, Diploma, etc.
  final String? thumbnailUrl;
  final List<String> modules;
  final int duration; // in hours
  final DateTime createdAt;
  final int studentsEnrolled;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.priceEmc,
    required this.category,
    this.thumbnailUrl,
    this.modules = const [],
    required this.duration,
    required this.createdAt,
    this.studentsEnrolled = 0,
  });

  // Alias for lecturerName (uses instructor)
  String get lecturerName => instructor;

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    return CourseModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructor: map['instructor'] ?? '',
      priceEmc: map['priceEmc'] ?? 0,
      category: map['category'] ?? 'Freemium',
      thumbnailUrl: map['thumbnailUrl'],
      modules: List<String>.from(map['modules'] ?? []),
      duration: map['duration'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      studentsEnrolled: map['studentsEnrolled'] ?? 0,
    );
  }

  // Firestore-specific factory
  factory CourseModel.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'instructor': instructor,
      'priceEmc': priceEmc,
      'category': category,
      'thumbnailUrl': thumbnailUrl,
      'modules': modules,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'studentsEnrolled': studentsEnrolled,
    };
  }
}
