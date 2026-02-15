import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certificate_model.dart';
import '../models/grade_model.dart';
import 'notification_service.dart';

class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Issue a course completion certificate
  Future<CertificateModel> issueCertificate({
    required String studentId,
    required String studentName,
    required String studentEmail,
    required String courseId,
    required String courseName,
    required String lecturerId,
    required String lecturerName,
    required String grade,
    required double gpa,
    required String semester,
    required String issuedById,
    required String issuedByName,
    CertificateType type = CertificateType.courseCompletion,
    String? remarks,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    
    // Generate unique certificate number
    final certificateNumber = CertificateModel.generateCertificateNumber(
      studentId,
      courseId,
      now,
    );
    
    // Generate verification URL (use your actual domain)
    final baseUrl = 'https://emtech.school'; // Update with actual domain
    final verificationUrl = CertificateModel.generateVerificationUrl(
      certificateNumber,
      baseUrl,
    );
    
    // QR code data (can be scanned to verify)
    final qrCodeData = verificationUrl;
    
    final certificate = CertificateModel(
      id: '', // Will be set by Firestore
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      courseId: courseId,
      courseName: courseName,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      grade: grade,
      gpa: gpa,
      completionDate: now,
      semester: semester,
      type: type,
      status: CertificateStatus.issued,
      certificateNumber: certificateNumber,
      verificationUrl: verificationUrl,
      qrCodeData: qrCodeData,
      issuedBy: issuedById,
      issuedByName: issuedByName,
      issuedAt: now,
      remarks: remarks,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
    
    // Save to Firestore
    final docRef = await _firestore.collection('certificates').add(certificate.toMap());
    
    // Send notification to student
      await _notificationService.createNotification(
      userId: studentId,
      type: 'certificate',
      title: 'Certificate Issued',
      message: 'Your certificate for $courseName has been issued! Grade: $grade',
    );
    
    return certificate.copyWith(id: docRef.id);
  }

  /// Get student's certificates
  Stream<List<CertificateModel>> getStudentCertificates(String studentId) {
    return _firestore
        .collection('certificates')
        .where('studentId', isEqualTo: studentId)
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificateModel.fromFirestore(doc))
            .toList());
  }

  /// Get certificate by ID
  Future<CertificateModel?> getCertificateById(String certificateId) async {
    final doc = await _firestore.collection('certificates').doc(certificateId).get();
    
    if (doc.exists) {
      return CertificateModel.fromFirestore(doc);
    }
    
    return null;
  }

  /// Verify certificate by certificate number
  Future<CertificateModel?> verifyCertificate(String certificateNumber) async {
    final snapshot = await _firestore
        .collection('certificates')
        .where('certificateNumber', isEqualTo: certificateNumber)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return CertificateModel.fromFirestore(snapshot.docs.first);
    }
    
    return null;
  }

  /// Get certificates for a course (lecturer view)
  Stream<List<CertificateModel>> getCourseCertificates(String courseId) {
    return _firestore
        .collection('certificates')
        .where('courseId', isEqualTo: courseId)
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificateModel.fromFirestore(doc))
            .toList());
  }

  /// Get all certificates (admin view)
  Stream<List<CertificateModel>> getAllCertificates({CertificateStatus? status}) {
    Query<Map<String, dynamic>> query = _firestore.collection('certificates');
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }
    
    return query
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificateModel.fromFirestore(doc))
            .toList());
  }

  /// Revoke a certificate
  Future<void> revokeCertificate({
    required String certificateId,
    required String revokedById,
    required String reason,
  }) async {
    await _firestore.collection('certificates').doc(certificateId).update({
      'status': CertificateStatus.revoked.toString().split('.').last,
      'revokedBy': revokedById,
      'revokedAt': FieldValue.serverTimestamp(),
      'revocationReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Get certificate to notify student
    final cert = await getCertificateById(certificateId);
    if (cert != null) {
      await _notificationService.createNotification(
        userId: cert.studentId,
        title: 'Certificate Revoked',
        message: 'Your certificate for ${cert.courseName} has been revoked. Reason: $reason',
        type: 'certificate',
      );
    }
  }

  /// Restore a revoked certificate
  Future<void> restoreCertificate(String certificateId) async {
    await _firestore.collection('certificates').doc(certificateId).update({
      'status': CertificateStatus.issued.toString().split('.').last,
      'revokedBy': null,
      'revokedAt': null,
      'revocationReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if student has certificate for a course
  Future<bool> hasCertificateForCourse(String studentId, String courseId) async {
    final snapshot = await _firestore
        .collection('certificates')
        .where('studentId', isEqualTo: studentId)
        .where('courseId', isEqualTo: courseId)
        .where('status', isEqualTo: CertificateStatus.issued.toString().split('.').last)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  /// Auto-issue certificate when grade is submitted (called by grading service)
  Future<void> autoIssueCertificateOnGrade(GradeModel grade) async {
    // Check if student already has a certificate for this course
    final hasExisting = await hasCertificateForCourse(grade.studentId, grade.courseId);
    
    if (hasExisting) {
      print('Certificate already exists for student ${grade.studentId} in course ${grade.courseId}');
      return;
    }
    
    // Only issue certificate for passing grades (C and above)
    final passingGrades = ['A', 'B', 'C'];
    if (!passingGrades.contains(grade.grade.toString().split('.').last)) {
      print('Grade ${grade.grade} does not qualify for certificate');
      return;
    }
    
    // Convert letter grade to GPA (simplified)
    final gradeToGPA = {
      LetterGrade.A: 4.0,
      LetterGrade.B: 3.0,
      LetterGrade.C: 2.0,
      LetterGrade.D: 1.0,
      LetterGrade.E: 0.5,
      LetterGrade.F: 0.0,
    };
    
    final gpa = gradeToGPA[grade.grade] ?? 0.0;
    
    await issueCertificate(
      studentId: grade.studentId,
      studentName: grade.studentName,
      studentEmail: grade.studentEmail,
      courseId: grade.courseId,
      courseName: grade.courseName,
      lecturerId: grade.lecturerId,
      lecturerName: grade.lecturerName,
      grade: grade.grade.toString().split('.').last,
      gpa: gpa,
      semester: grade.semester,
      issuedById: grade.lecturerId, // Lecturer who graded
      issuedByName: grade.lecturerName,
      type: CertificateType.courseCompletion,
      metadata: {
        'numericScore': grade.numericScore,
        'emcReward': grade.emcReward,
        'gradedAt': grade.gradedAt.toIso8601String(),
      },
    );
  }

  /// Get certificate statistics
  Future<Map<String, int>> getCertificateStats() async {
    final allCerts = await _firestore.collection('certificates').get();
    
    int issued = 0;
    int revoked = 0;
    int courseCompletion = 0;
    int graduation = 0;
    
    for (final doc in allCerts.docs) {
      final data = doc.data();
      final status = data['status'] ?? '';
      final type = data['type'] ?? '';
      
      if (status == 'issued') issued++;
      if (status == 'revoked') revoked++;
      if (type == 'courseCompletion') courseCompletion++;
      if (type == 'graduation') graduation++;
    }
    
    return {
      'total': allCerts.docs.length,
      'issued': issued,
      'revoked': revoked,
      'courseCompletion': courseCompletion,
      'graduation': graduation,
    };
  }

  /// Get certificates issued this month
  Future<int> getCertificatesIssuedThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    final snapshot = await _firestore
        .collection('certificates')
        .where('issuedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();
    
    return snapshot.docs.length;
  }

  /// Search certificates
  Future<List<CertificateModel>> searchCertificates(String query) async {
    final snapshot = await _firestore.collection('certificates').get();
    
    return snapshot.docs
        .map((doc) => CertificateModel.fromFirestore(doc))
        .where((cert) =>
            cert.studentName.toLowerCase().contains(query.toLowerCase()) ||
            cert.certificateNumber.toLowerCase().contains(query.toLowerCase()) ||
            cert.courseName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
