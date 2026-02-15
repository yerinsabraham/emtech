import 'package:cloud_firestore/cloud_firestore.dart';

/// Certificate status
enum CertificateStatus {
  issued,
  revoked,
  pending,
}

/// Certificate type
enum CertificateType {
  courseCompletion,
  graduation,
  excellence,
  participation,
}

class CertificateModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  
  // Course/Program details
  final String courseId;
  final String courseName;
  final String lecturerId;
  final String lecturerName;
  
  // Academic details
  final String grade; // 'A', 'B', 'C', etc.
  final double gpa;
  final DateTime completionDate;
  final String semester; // e.g., "2026-1"
  
  // Certificate metadata
  final CertificateType type;
  final CertificateStatus status;
  final String certificateNumber; // Unique verification code
  final String verificationUrl; // Public verification link
  final String qrCodeData; // QR code content
  
  // Issuance details
  final String issuedBy; // Admin/Lecturer UID
  final String issuedByName;
  final DateTime issuedAt;
  final String? revokedBy;
  final DateTime? revokedAt;
  final String? revocationReason;
  
  // Additional info
  final String? remarks;
  final Map<String, dynamic>? metadata; // Extra course-specific data
  
  final DateTime createdAt;
  final DateTime updatedAt;

  CertificateModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.courseId,
    required this.courseName,
    required this.lecturerId,
    required this.lecturerName,
    required this.grade,
    required this.gpa,
    required this.completionDate,
    required this.semester,
    this.type = CertificateType.courseCompletion,
    this.status = CertificateStatus.issued,
    required this.certificateNumber,
    required this.verificationUrl,
    required this.qrCodeData,
    required this.issuedBy,
    required this.issuedByName,
    required this.issuedAt,
    this.revokedBy,
    this.revokedAt,
    this.revocationReason,
    this.remarks,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CertificateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CertificateModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentEmail: data['studentEmail'] ?? '',
      courseId: data['courseId'] ?? '',
      courseName: data['courseName'] ?? '',
      lecturerId: data['lecturerId'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      grade: data['grade'] ?? '',
      gpa: (data['gpa'] ?? 0).toDouble(),
      completionDate: (data['completionDate'] as Timestamp).toDate(),
      semester: data['semester'] ?? '',
      type: CertificateType.values.firstWhere(
        (e) => e.toString() == 'CertificateType.${data['type']}',
        orElse: () => CertificateType.courseCompletion,
      ),
      status: CertificateStatus.values.firstWhere(
        (e) => e.toString() == 'CertificateStatus.${data['status']}',
        orElse: () => CertificateStatus.issued,
      ),
      certificateNumber: data['certificateNumber'] ?? '',
      verificationUrl: data['verificationUrl'] ?? '',
      qrCodeData: data['qrCodeData'] ?? '',
      issuedBy: data['issuedBy'] ?? '',
      issuedByName: data['issuedByName'] ?? '',
      issuedAt: (data['issuedAt'] as Timestamp).toDate(),
      revokedBy: data['revokedBy'],
      revokedAt: data['revokedAt'] != null ? (data['revokedAt'] as Timestamp).toDate() : null,
      revocationReason: data['revocationReason'],
      remarks: data['remarks'],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'courseId': courseId,
      'courseName': courseName,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'grade': grade,
      'gpa': gpa,
      'completionDate': Timestamp.fromDate(completionDate),
      'semester': semester,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'certificateNumber': certificateNumber,
      'verificationUrl': verificationUrl,
      'qrCodeData': qrCodeData,
      'issuedBy': issuedBy,
      'issuedByName': issuedByName,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'revokedBy': revokedBy,
      'revokedAt': revokedAt != null ? Timestamp.fromDate(revokedAt!) : null,
      'revocationReason': revocationReason,
      'remarks': remarks,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Generate a human-readable certificate number
  static String generateCertificateNumber(String studentId, String courseId, DateTime date) {
    final year = date.year;
    final studentCode = studentId.substring(0, 6).toUpperCase();
    final courseCode = courseId.substring(0, 4).toUpperCase();
    final timestamp = date.millisecondsSinceEpoch.toString().substring(6, 12);
    
    return 'EMC-$year-$studentCode-$courseCode-$timestamp';
  }

  /// Generate verification URL
  static String generateVerificationUrl(String certificateNumber, String baseUrl) {
    return '$baseUrl/verify-certificate/$certificateNumber';
  }

  /// Status display
  String get statusDisplay {
    switch (status) {
      case CertificateStatus.issued:
        return 'Valid';
      case CertificateStatus.revoked:
        return 'Revoked';
      case CertificateStatus.pending:
        return 'Pending';
    }
  }

  /// Type display
  String get typeDisplay {
    switch (type) {
      case CertificateType.courseCompletion:
        return 'Course Completion';
      case CertificateType.graduation:
        return 'Graduation';
      case CertificateType.excellence:
        return 'Academic Excellence';
      case CertificateType.participation:
        return 'Participation';
    }
  }

  /// Check if certificate is valid
  bool get isValid => status == CertificateStatus.issued;

  /// Get status color
  String get statusColor {
    switch (status) {
      case CertificateStatus.issued:
        return '#22C55E'; // Green
      case CertificateStatus.revoked:
        return '#EF4444'; // Red
      case CertificateStatus.pending:
        return '#F59E0B'; // Amber
    }
  }

  CertificateModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? courseId,
    String? courseName,
    String? lecturerId,
    String? lecturerName,
    String? grade,
    double? gpa,
    DateTime? completionDate,
    String? semester,
    CertificateType? type,
    CertificateStatus? status,
    String? certificateNumber,
    String? verificationUrl,
    String? qrCodeData,
    String? issuedBy,
    String? issuedByName,
    DateTime? issuedAt,
    String? revokedBy,
    DateTime? revokedAt,
    String? revocationReason,
    String? remarks,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CertificateModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      lecturerId: lecturerId ?? this.lecturerId,
      lecturerName: lecturerName ?? this.lecturerName,
      grade: grade ?? this.grade,
      gpa: gpa ?? this.gpa,
      completionDate: completionDate ?? this.completionDate,
      semester: semester ?? this.semester,
      type: type ?? this.type,
      status: status ?? this.status,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      issuedBy: issuedBy ?? this.issuedBy,
      issuedByName: issuedByName ?? this.issuedByName,
      issuedAt: issuedAt ?? this.issuedAt,
      revokedBy: revokedBy ?? this.revokedBy,
      revokedAt: revokedAt ?? this.revokedAt,
      revocationReason: revocationReason ?? this.revocationReason,
      remarks: remarks ?? this.remarks,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
