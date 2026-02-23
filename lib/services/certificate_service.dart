import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/certificate_model.dart';
import '../models/grade_model.dart';
import 'notification_service.dart';
import 'achievement_service.dart';

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

    // Trigger achievement check for certificate issued
    final certCount = await _firestore
        .collection('certificates')
        .where('studentId', isEqualTo: studentId)
        .count()
        .get();
    unawaited(AchievementService().onCertificateIssued(studentId, certCount.count ?? 1));

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

  /// Generate a PDF for the given certificate and trigger the system share/save dialog
  Future<void> generateAndSharePdf(CertificateModel certificate) async {
    final pdf = pw.Document();

    // Try to load the app logo; fall back gracefully if asset not found
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/emtechlogo.jpeg');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final gold = PdfColor.fromHex('#D4AF37');
    final darkText = PdfColor.fromHex('#1A1A1A');
    final grayText = PdfColor.fromHex('#666666');
    final lightGray = PdfColor.fromHex('#999999');
    final creamBg = PdfColor.fromHex('#FFFFF5');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(0),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: creamBg,
              border: pw.Border.all(color: gold, width: 8),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Logo + school name row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (logoImage != null) ...[
                        pw.Image(logoImage, width: 50, height: 50),
                        pw.SizedBox(width: 12),
                      ],
                      pw.Text(
                        'EMTECH SCHOOL',
                        style: pw.TextStyle(
                          fontSize: 30,
                          fontWeight: pw.FontWeight.bold,
                          color: darkText,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Certificate of Completion',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontStyle: pw.FontStyle.italic,
                      color: grayText,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(width: 200, height: 2, color: gold),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'This is to certify that',
                    style: pw.TextStyle(fontSize: 13, color: grayText),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    certificate.studentName,
                    style: pw.TextStyle(
                      fontSize: 36,
                      fontWeight: pw.FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'has successfully completed the course',
                    style: pw.TextStyle(fontSize: 13, color: grayText),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    certificate.courseName,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: darkText,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'with a grade of ${certificate.grade}  |  GPA: ${certificate.gpa.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 13, color: grayText),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Container(width: 200, height: 1, color: PdfColor.fromHex('#CCCCCC')),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _pdfSignatureBlock(
                        DateFormat('MMMM dd, yyyy').format(certificate.completionDate),
                        'Date of Completion',
                        darkText,
                        lightGray,
                        gold,
                      ),
                      _pdfSignatureBlock(
                        certificate.issuedByName,
                        'Authorized Signatory',
                        darkText,
                        lightGray,
                        gold,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Certificate No: ${certificate.certificateNumber}',
                    style: pw.TextStyle(fontSize: 9, color: lightGray),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Verify at: ${certificate.verificationUrl}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromHex('#3B82F6'),
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final filename = 'certificate_${certificate.certificateNumber}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  static pw.Widget _pdfSignatureBlock(
    String value,
    String label,
    PdfColor darkColor,
    PdfColor lightColor,
    PdfColor lineColor,
  ) {
    return pw.Column(
      children: [
        pw.Container(width: 150, height: 1, color: lightColor),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 11, color: darkColor)),
        pw.Text(label,
            style: pw.TextStyle(fontSize: 9, color: lightColor)),
      ],
    );
  }
}
