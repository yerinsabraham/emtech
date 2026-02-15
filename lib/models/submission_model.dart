import 'package:cloud_firestore/cloud_firestore.dart';

enum SubmissionType {
  assignment,
  exam,
}

enum SubmissionStatus {
  submitted,
  graded,
  returned,
  late,
}

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String? examId;
  final SubmissionType type;
  final String courseId;
  final String courseName;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String? textSubmission;
  final String? fileUrl; // Firebase Storage URL
  final List<int>? examAnswers; // For exam: selected answer indices
  final DateTime submittedAt;
  final SubmissionStatus status;
  final double? score; // Points earned
  final double? totalPoints; // Total possible points
  final String? grade; // Letter grade (A-E)
  final String? feedback;
  final DateTime? gradedAt;
  final String? gradedByLecturerId;
  final String? gradedByLecturerName;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    this.examId,
    required this.type,
    required this.courseId,
    required this.courseName,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.textSubmission,
    this.fileUrl,
    this.examAnswers,
    required this.submittedAt,
    this.status = SubmissionStatus.submitted,
    this.score,
    this.totalPoints,
    this.grade,
    this.feedback,
    this.gradedAt,
    this.gradedByLecturerId,
    this.gradedByLecturerName,
  });

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubmissionModel(
      id: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      examId: data['examId'],
      type: SubmissionType.values.firstWhere(
        (e) => e.toString() == 'SubmissionType.${data['type']}',
        orElse: () => SubmissionType.assignment,
      ),
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      textSubmission: data['textSubmission'],
      fileUrl: data['fileUrl'],
      examAnswers: data['examAnswers'] != null
          ? List<int>.from(data['examAnswers'])
          : null,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      status: SubmissionStatus.values.firstWhere(
        (e) => e.toString() == 'SubmissionStatus.${data['status']}',
        orElse: () => SubmissionStatus.submitted,
      ),
      score: data['score']?.toDouble(),
      totalPoints: data['totalPoints']?.toDouble(),
      grade: data['grade'],
      feedback: data['feedback'],
      gradedAt: data['gradedAt'] != null
          ? (data['gradedAt'] as Timestamp).toDate()
          : null,
      gradedByLecturerId: data['gradedByLecturerId'],
      gradedByLecturerName: data['gradedByLecturerName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'assignmentId': assignmentId,
      'examId': examId,
      'type': type.toString().split('.').last,
      'courseId': courseId,
      'courseName': courseName,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'textSubmission': textSubmission,
      'fileUrl': fileUrl,
      'examAnswers': examAnswers,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.toString().split('.').last,
      'score': score,
      'totalPoints': totalPoints,
      'grade': grade,
      'feedback': feedback,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
      'gradedByLecturerId': gradedByLecturerId,
      'gradedByLecturerName': gradedByLecturerName,
    };
  }

  bool get isGraded => status == SubmissionStatus.graded || status == SubmissionStatus.returned;
  double? get percentageScore => totalPoints != null && totalPoints! > 0
      ? (score ?? 0) / totalPoints! * 100
      : null;
}
