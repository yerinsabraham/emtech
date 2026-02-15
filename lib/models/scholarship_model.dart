import 'package:cloud_firestore/cloud_firestore.dart';

/// Scholarship deposit status
enum ScholarshipDepositStatus {
  pending,
  deposited,
  released,
  forfeited,
}

/// Scholarship type
enum ScholarshipType {
  full, // 100% scholarship
  partial, // 50% or other percentage
  merit, // Merit-based
  need, // Need-based
}

class ScholarshipModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  
  // Scholarship details
  final ScholarshipType type;
  final double percentage; // 100.0 for full, 50.0 for half, etc.
  final double originalTuitionFee; // Full tuition amount
  final double scholarshipAmount; // Amount covered by scholarship
  final double depositRequired; // 30% of tuition for 100% scholarship
  
  // Deposit tracking
  final ScholarshipDepositStatus depositStatus;
  final double depositPaid;
  final DateTime? depositPaidAt;
  final String? depositTransactionId;
  
  // Eligibility & Requirements
  final double minimumGradeRequired; // e.g., 2.0 GPA or 'C' grade
  final String? minimumLetterGrade; // 'C', 'B', etc.
  final String courseId;
  final String courseName;
  final String semester;
  
  // Graduation & Release
  final bool hasGraduated;
  final DateTime? graduationDate;
  final double? finalGPA;
  final String? finalGrade;
  final bool meetsMinimumRequirement;
  
  // Deposit release/forfeiture
  final DateTime? releasedAt;
  final String? releasedBy;
  final double? releasedAmount;
  final DateTime? forfeitedAt;
  final String? forfeitedBy;
  final String? forfeitureReason;
  
  // Administrative
  final String approvedBy; // Admin who approved scholarship
  final String approvedByName;
  final DateTime approvedAt;
  final String? remarks;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  ScholarshipModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.type,
    required this.percentage,
    required this.originalTuitionFee,
    required this.scholarshipAmount,
    required this.depositRequired,
    this.depositStatus = ScholarshipDepositStatus.pending,
    this.depositPaid = 0.0,
    this.depositPaidAt,
    this.depositTransactionId,
    this.minimumGradeRequired = 2.0,
    this.minimumLetterGrade = 'C',
    required this.courseId,
    required this.courseName,
    required this.semester,
    this.hasGraduated = false,
    this.graduationDate,
    this.finalGPA,
    this.finalGrade,
    this.meetsMinimumRequirement = false,
    this.releasedAt,
    this.releasedBy,
    this.releasedAmount,
    this.forfeitedAt,
    this.forfeitedBy,
    this.forfeitureReason,
    required this.approvedBy,
    required this.approvedByName,
    required this.approvedAt,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScholarshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ScholarshipModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      type: ScholarshipType.values.firstWhere(
        (e) => e.toString() == 'ScholarshipType.${data['type']}',
        orElse: () => ScholarshipType.full,
      ),
      percentage: (data['percentage'] ?? 100.0).toDouble(),
      originalTuitionFee: (data['originalTuitionFee'] ?? 0).toDouble(),
      scholarshipAmount: (data['scholarshipAmount'] ?? 0).toDouble(),
      depositRequired: (data['depositRequired'] ?? 0).toDouble(),
      depositStatus: ScholarshipDepositStatus.values.firstWhere(
        (e) => e.toString() == 'ScholarshipDepositStatus.${data['depositStatus']}',
        orElse: () => ScholarshipDepositStatus.pending,
      ),
      depositPaid: (data['depositPaid'] ?? 0).toDouble(),
      depositPaidAt: data['depositPaidAt'] != null 
          ? (data['depositPaidAt'] as Timestamp).toDate() 
          : null,
      depositTransactionId: data['depositTransactionId'],
      minimumGradeRequired: (data['minimumGradeRequired'] ?? 2.0).toDouble(),
      minimumLetterGrade: data['minimumLetterGrade'] ?? 'C',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      semester: data['semester'] ?? '',
      hasGraduated: data['hasGraduated'] ?? false,
      graduationDate: data['graduationDate'] != null 
          ? (data['graduationDate'] as Timestamp).toDate() 
          : null,
      finalGPA: data['finalGPA']?.toDouble(),
      finalGrade: data['finalGrade'],
      meetsMinimumRequirement: data['meetsMinimumRequirement'] ?? false,
      releasedAt: data['releasedAt'] != null 
          ? (data['releasedAt'] as Timestamp).toDate() 
          : null,
      releasedBy: data['releasedBy'],
      releasedAmount: data['releasedAmount']?.toDouble(),
      forfeitedAt: data['forfeitedAt'] != null 
          ? (data['forfeitedAt'] as Timestamp).toDate() 
          : null,
      forfeitedBy: data['forfeitedBy'],
      forfeitureReason: data['forfeitureReason'],
      approvedBy: data['approvedBy'] ?? '',
      approvedByName: data['approvedByName'] ?? '',
      approvedAt: (data['approvedAt'] as Timestamp).toDate(),
      remarks: data['remarks'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'type': type.toString().split('.').last,
      'percentage': percentage,
      'originalTuitionFee': originalTuitionFee,
      'scholarshipAmount': scholarshipAmount,
      'depositRequired': depositRequired,
      'depositStatus': depositStatus.toString().split('.').last,
      'depositPaid': depositPaid,
      'depositPaidAt': depositPaidAt != null ? Timestamp.fromDate(depositPaidAt!) : null,
      'depositTransactionId': depositTransactionId,
      'minimumGradeRequired': minimumGradeRequired,
      'minimumLetterGrade': minimumLetterGrade,
      'courseId': courseId,
      'courseName': courseName,
      'semester': semester,
      'hasGraduated': hasGraduated,
      'graduationDate': graduationDate != null ? Timestamp.fromDate(graduationDate!) : null,
      'finalGPA': finalGPA,
      'finalGrade': finalGrade,
      'meetsMinimumRequirement': meetsMinimumRequirement,
      'releasedAt': releasedAt != null ? Timestamp.fromDate(releasedAt!) : null,
      'releasedBy': releasedBy,
      'releasedAmount': releasedAmount,
      'forfeitedAt': forfeitedAt != null ? Timestamp.fromDate(forfeitedAt!) : null,
      'forfeitedBy': forfeitedBy,
      'forfeitureReason': forfeitureReason,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': Timestamp.fromDate(approvedAt),
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Calculate deposit requirement (30% of tuition for 100% scholarship)
  static double calculateDepositRequired(double tuitionFee, double scholarshipPercentage) {
    if (scholarshipPercentage >= 100.0) {
      return tuitionFee * 0.30; // 30% deposit for full scholarship
    }
    return 0.0; // No deposit for partial scholarships
  }

  /// Check if minimum requirement is met
  static bool checkMinimumRequirement(double? gpa, String? letterGrade, double minGPA, String? minLetterGrade) {
    if (gpa != null && gpa >= minGPA) {
      return true;
    }
    
    if (letterGrade != null && minLetterGrade != null) {
      final gradeValue = {'A': 5, 'B': 4, 'C': 3, 'D': 2, 'E': 1, 'F': 0};
      final actualValue = gradeValue[letterGrade] ?? 0;
      final minValue = gradeValue[minLetterGrade] ?? 0;
      return actualValue >= minValue;
    }
    
    return false;
  }

  /// Deposit status display
  String get depositStatusDisplay {
    switch (depositStatus) {
      case ScholarshipDepositStatus.pending:
        return 'Pending Payment';
      case ScholarshipDepositStatus.deposited:
        return 'Deposited';
      case ScholarshipDepositStatus.released:
        return 'Released';
      case ScholarshipDepositStatus.forfeited:
        return 'Forfeited';
    }
  }

  /// Scholarship type display
  String get typeDisplay {
    switch (type) {
      case ScholarshipType.full:
        return 'Full Scholarship (100%)';
      case ScholarshipType.partial:
        return 'Partial Scholarship ($percentage%)';
      case ScholarshipType.merit:
        return 'Merit-Based Scholarship';
      case ScholarshipType.need:
        return 'Need-Based Scholarship';
    }
  }

  /// Get deposit status color
  String get statusColor {
    switch (depositStatus) {
      case ScholarshipDepositStatus.pending:
        return '#F59E0B'; // Amber
      case ScholarshipDepositStatus.deposited:
        return '#3B82F6'; // Blue
      case ScholarshipDepositStatus.released:
        return '#22C55E'; // Green
      case ScholarshipDepositStatus.forfeited:
        return '#EF4444'; // Red
    }
  }

  /// Check if deposit is fully paid
  bool get isDepositFullyPaid => depositPaid >= depositRequired;

  /// Remaining deposit amount
  double get remainingDeposit => (depositRequired - depositPaid).clamp(0.0, depositRequired);

  ScholarshipModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentEmail,
    ScholarshipType? type,
    double? percentage,
    double? originalTuitionFee,
    double? scholarshipAmount,
    double? depositRequired,
    ScholarshipDepositStatus? depositStatus,
    double? depositPaid,
    DateTime? depositPaidAt,
    String? depositTransactionId,
    double? minimumGradeRequired,
    String? minimumLetterGrade,
    String? courseId,
    String? courseName,
    String? semester,
    bool? hasGraduated,
    DateTime? graduationDate,
    double? finalGPA,
    String? finalGrade,
    bool? meetsMinimumRequirement,
    DateTime? releasedAt,
    String? releasedBy,
    double? releasedAmount,
    DateTime? forfeitedAt,
    String? forfeitedBy,
    String? forfeitureReason,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScholarshipModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      type: type ?? this.type,
      percentage: percentage ?? this.percentage,
      originalTuitionFee: originalTuitionFee ?? this.originalTuitionFee,
      scholarshipAmount: scholarshipAmount ?? this.scholarshipAmount,
      depositRequired: depositRequired ?? this.depositRequired,
      depositStatus: depositStatus ?? this.depositStatus,
      depositPaid: depositPaid ?? this.depositPaid,
      depositPaidAt: depositPaidAt ?? this.depositPaidAt,
      depositTransactionId: depositTransactionId ?? this.depositTransactionId,
      minimumGradeRequired: minimumGradeRequired ?? this.minimumGradeRequired,
      minimumLetterGrade: minimumLetterGrade ?? this.minimumLetterGrade,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      semester: semester ?? this.semester,
      hasGraduated: hasGraduated ?? this.hasGraduated,
      graduationDate: graduationDate ?? this.graduationDate,
      finalGPA: finalGPA ?? this.finalGPA,
      finalGrade: finalGrade ?? this.finalGrade,
      meetsMinimumRequirement: meetsMinimumRequirement ?? this.meetsMinimumRequirement,
      releasedAt: releasedAt ?? this.releasedAt,
      releasedBy: releasedBy ?? this.releasedBy,
      releasedAmount: releasedAmount ?? this.releasedAmount,
      forfeitedAt: forfeitedAt ?? this.forfeitedAt,
      forfeitedBy: forfeitedBy ?? this.forfeitedBy,
      forfeitureReason: forfeitureReason ?? this.forfeitureReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
