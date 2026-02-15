import 'package:cloud_firestore/cloud_firestore.dart';

enum LetterGrade {
  A,
  B,
  C,
  D,
  E,
  F, // Fail
}

class GradeModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String courseId;
  final String courseName;
  final LetterGrade grade;
  final double numericScore; // 0-100
  final double emcReward; // EMC tokens earned
  final String lecturerId;
  final String lecturerName;
  final DateTime gradedAt;
  final String semester; // e.g., "2026-1", "2026-2"
  final bool isRedeemed; // Whether EMC reward has been redeemed
  final DateTime? redeemedAt;
  final String? comments;

  GradeModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.courseId,
    required this.courseName,
    required this.grade,
    required this.numericScore,
    required this.emcReward,
    required this.lecturerId,
    required this.lecturerName,
    required this.gradedAt,
    required this.semester,
    this.isRedeemed = false,
    this.redeemedAt,
    this.comments,
  });

  factory GradeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GradeModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      grade: LetterGrade.values.firstWhere(
        (e) => e.toString() == 'LetterGrade.${data['grade']}',
        orElse: () => LetterGrade.F,
      ),
      numericScore: (data['numericScore'] ?? 0).toDouble(),
      emcReward: (data['emcReward'] ?? 0).toDouble(),
      lecturerId: data['lecturerId'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      gradedAt: (data['gradedAt'] as Timestamp).toDate(),
      semester: data['semester'] ?? '',
      isRedeemed: data['isRedeemed'] ?? false,
      redeemedAt: data['redeemedAt'] != null
          ? (data['redeemedAt'] as Timestamp).toDate()
          : null,
      comments: data['comments'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'courseId': courseId,
      'courseName': courseName,
      'grade': grade.toString().split('.').last,
      'numericScore': numericScore,
      'emcReward': emcReward,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'gradedAt': Timestamp.fromDate(gradedAt),
      'semester': semester,
      'isRedeemed': isRedeemed,
      'redeemedAt': redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
      'comments': comments,
    };
  }

  // Calculate EMC reward based on grade
  static double calculateEmcReward(LetterGrade grade, bool isPaidCourse) {
    final baseReward = isPaidCourse ? 2000.0 : 1000.0;
    
    switch (grade) {
      case LetterGrade.A:
        return baseReward * 1.5; // 150% bonus
      case LetterGrade.B:
        return baseReward * 1.25; // 125% bonus
      case LetterGrade.C:
        return baseReward * 1.0; // Base reward
      case LetterGrade.D:
        return baseReward * 0.75; // 75% of base
      case LetterGrade.E:
        return baseReward * 0.5; // 50% of base
      case LetterGrade.F:
        return 0; // No reward for fail
    }
  }

  // Convert numeric score to letter grade
  static LetterGrade numericToLetterGrade(double score) {
    if (score >= 90) return LetterGrade.A;
    if (score >= 80) return LetterGrade.B;
    if (score >= 70) return LetterGrade.C;
    if (score >= 60) return LetterGrade.D;
    if (score >= 50) return LetterGrade.E;
    return LetterGrade.F;
  }

  bool get isPassing => grade != LetterGrade.F;
}
