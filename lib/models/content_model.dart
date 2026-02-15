import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType {
  video,
  document,
  presentation,
  link,
  other,
}

enum ContentAccessLevel {
  freemium, // Free content (Admin uploads)
  premium, // Paid course content (Lecturer uploads)
}

class ContentModel {
  final String id;
  final String courseId;
  final String courseName;
  final String title;
  final String description;
  final ContentType type;
  final String fileUrl; // Firebase Storage URL or external link
  final String? thumbnailUrl;
  final ContentAccessLevel accessLevel;
  final String uploadedById;
  final String uploadedByName;
  final String uploadedByRole; // 'admin' or 'lecturer'
  final DateTime createdAt;
  final int viewCount;
  final int downloadCount;
  final int fileSizeBytes;
  final String? mimeType;

  ContentModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.description,
    required this.type,
    required this.fileUrl,
    this.thumbnailUrl,
    required this.accessLevel,
    required this.uploadedById,
    required this.uploadedByName,
    required this.uploadedByRole,
    required this.createdAt,
    this.viewCount = 0,
    this.downloadCount = 0,
    this.fileSizeBytes = 0,
    this.mimeType,
  });

  factory ContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: ContentType.values.firstWhere(
        (e) => e.toString() == 'ContentType.${data['type']}',
        orElse: () => ContentType.other,
      ),
      fileUrl: data['fileUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      accessLevel: ContentAccessLevel.values.firstWhere(
        (e) => e.toString() == 'ContentAccessLevel.${data['accessLevel']}',
        orElse: () => ContentAccessLevel.premium,
      ),
      uploadedById: data['uploadedById'] ?? '',
      uploadedByName: data['uploadedByName'] ?? '',
      uploadedByRole: data['uploadedByRole'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      viewCount: data['viewCount'] ?? 0,
      downloadCount: data['downloadCount'] ?? 0,
      fileSizeBytes: data['fileSizeBytes'] ?? 0,
      mimeType: data['mimeType'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'accessLevel': accessLevel.toString().split('.').last,
      'uploadedById': uploadedById,
      'uploadedByName': uploadedByName,
      'uploadedByRole': uploadedByRole,
      'createdAt': Timestamp.fromDate(createdAt),
      'viewCount': viewCount,
      'downloadCount': downloadCount,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
    };
  }

  bool get isFreemium => accessLevel == ContentAccessLevel.freemium;
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
