import 'package:cloud_firestore/cloud_firestore.dart';

enum ExamStatus {
  draft,
  pendingApproval,
  approved,
  rejected,
  published,
  closed,
}

class ExamQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final int points;

  ExamQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.points,
  });

  factory ExamQuestion.fromMap(Map<String, dynamic> data) {
    return ExamQuestion(
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
      points: data['points'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'points': points,
    };
  }
}

class ExamModel {
  final String id;
  final String courseId;
  final String courseName;
  final String lecturerId;
  final String lecturerName;
  final String title;
  final String description;
  final List<ExamQuestion> questions;
  final int totalPoints;
  final int durationMinutes;
  final DateTime scheduledDate;
  final ExamStatus status;
  final DateTime createdAt;
  final DateTime? submittedForApprovalAt;
  final DateTime? approvedAt;
  final String? approvedByAdminId;
  final String? approvedByAdminName;
  final String? rejectionReason;
  final int attemptCount; // Number of students who took the exam

  ExamModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.lecturerId,
    required this.lecturerName,
    required this.title,
    required this.description,
    required this.questions,
    required this.totalPoints,
    required this.durationMinutes,
    required this.scheduledDate,
    this.status = ExamStatus.draft,
    required this.createdAt,
    this.submittedForApprovalAt,
    this.approvedAt,
    this.approvedByAdminId,
    this.approvedByAdminName,
    this.rejectionReason,
    this.attemptCount = 0,
  });

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      questions: (data['questions'] as List<dynamic>?)
              ?.map((q) => ExamQuestion.fromMap(q as Map<String, dynamic>))
              .toList() ??
          [],
      totalPoints: data['totalPoints'] ?? 0,
      durationMinutes: data['durationMinutes'] ?? 60,
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      status: ExamStatus.values.firstWhere(
        (e) => e.toString() == 'ExamStatus.${data['status']}',
        orElse: () => ExamStatus.draft,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      submittedForApprovalAt: data['submittedForApprovalAt'] != null
          ? (data['submittedForApprovalAt'] as Timestamp).toDate()
          : null,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      approvedByAdminId: data['approvedByAdminId'],
      approvedByAdminName: data['approvedByAdminName'],
      rejectionReason: data['rejectionReason'],
      attemptCount: data['attemptCount'] ?? 0,
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
      'questions': questions.map((q) => q.toMap()).toList(),
      'totalPoints': totalPoints,
      'durationMinutes': durationMinutes,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'submittedForApprovalAt': submittedForApprovalAt != null
          ? Timestamp.fromDate(submittedForApprovalAt!)
          : null,
      'approvedAt':
          approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedByAdminId': approvedByAdminId,
      'approvedByAdminName': approvedByAdminName,
      'rejectionReason': rejectionReason,
      'attemptCount': attemptCount,
    };
  }

  bool get isPending => status == ExamStatus.pendingApproval;
  bool get isApproved => status == ExamStatus.approved || status == ExamStatus.published;
  bool get isRejected => status == ExamStatus.rejected;
}
