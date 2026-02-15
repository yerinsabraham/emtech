class LiveClassModel {
  final String id;
  final String title;
  final String description;
  final String instructorId;
  final String instructorName;
  final String courseId;
  final String courseName;
  final String youtubeUrl; // YouTube Live URL
  final String? youtubeVideoId; // Extracted video ID
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String status; // 'scheduled', 'live', 'ended'
  final int viewerCount;
  final DateTime createdAt;

  LiveClassModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorId,
    required this.instructorName,
    required this.courseId,
    required this.courseName,
    required this.youtubeUrl,
    this.youtubeVideoId,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.status = 'scheduled',
    this.viewerCount = 0,
    required this.createdAt,
  });

  factory LiveClassModel.fromMap(Map<String, dynamic> map, String id) {
    return LiveClassModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructorId: map['instructorId'] ?? '',
      instructorName: map['instructorName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      youtubeUrl: map['youtubeUrl'] ?? '',
      youtubeVideoId: map['youtubeVideoId'],
      scheduledAt: DateTime.parse(map['scheduledAt']),
      startedAt: map['startedAt'] != null ? DateTime.parse(map['startedAt']) : null,
      endedAt: map['endedAt'] != null ? DateTime.parse(map['endedAt']) : null,
      status: map['status'] ?? 'scheduled',
      viewerCount: map['viewerCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'courseId': courseId,
      'courseName': courseName,
      'youtubeUrl': youtubeUrl,
      'youtubeVideoId': youtubeVideoId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'status': status,
      'viewerCount': viewerCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Extract YouTube video ID from URL
  static String? extractVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  LiveClassModel copyWith({
    String? title,
    String? description,
    String? youtubeUrl,
    String? youtubeVideoId,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    String? status,
    int? viewerCount,
  }) {
    return LiveClassModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructorId: instructorId,
      instructorName: instructorName,
      courseId: courseId,
      courseName: courseName,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      viewerCount: viewerCount ?? this.viewerCount,
      createdAt: createdAt,
    );
  }
}
