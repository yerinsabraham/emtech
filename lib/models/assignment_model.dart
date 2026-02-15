import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String courseId;
  final String courseName;
  final String lecturerId;
  final String lecturerName;
  final String title;
  final String description;
  final String? attachmentUrl; // Firebase Storage URL
  final DateTime dueDate;
  final int totalPoints;
  final DateTime createdAt;
  final bool isPublished; // Draft vs Published
  final int submissionCount;

  AssignmentModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.lecturerId,
    required this.lecturerName,
    required this.title,
    required this.description,
    this.attachmentUrl,
    required this.dueDate,
    required this.totalPoints,
    required this.createdAt,
    this.isPublished = true,
    this.submissionCount = 0,
  });

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssignmentModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      totalPoints: data['totalPoints'] ?? 100,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPublished: data['isPublished'] ?? true,
      submissionCount: data['submissionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'title': title,
      'description': description,
      'attachmentUrl': attachmentUrl,
      'dueDate': Timestamp.fromDate(dueDate),
      'totalPoints': totalPoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublished': isPublished,
      'submissionCount': submissionCount,
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate);
}
