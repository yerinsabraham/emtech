import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scholarship_model.dart';
import 'notification_service.dart';

class ScholarshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Create a scholarship record
  Future<ScholarshipModel> createScholarship({
    required String studentId,
    required String studentName,
    required String studentEmail,
    required ScholarshipType type,
    required double percentage,
    required double originalTuitionFee,
    required String courseId,
    required String courseName,
    required String semester,
    required String approvedById,
    required String approvedByName,
    double minimumGradeRequired = 2.0,
    String? minimumLetterGrade = 'C',
    String? remarks,
  }) async {
    final now = DateTime.now();
    
    // Calculate scholarship amount and deposit required
    final scholarshipAmount = originalTuitionFee * (percentage / 100);
    final depositRequired = ScholarshipModel.calculateDepositRequired(
      originalTuitionFee,
      percentage,
    );
    
    final scholarship = ScholarshipModel(
      id: '',
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      type: type,
      percentage: percentage,
      originalTuitionFee: originalTuitionFee,
      scholarshipAmount: scholarshipAmount,
      depositRequired: depositRequired,
      depositStatus: ScholarshipDepositStatus.pending,
      minimumGradeRequired: minimumGradeRequired,
      minimumLetterGrade: minimumLetterGrade,
      courseId: courseId,
      courseName: courseName,
      semester: semester,
      approvedBy: approvedById,
      approvedByName: approvedByName,
      approvedAt: now,
      remarks: remarks,
      createdAt: now,
      updatedAt: now,
    );
    
    final docRef = await _firestore.collection('scholarships').add(scholarship.toMap());
    
    // Send notification to student
    await _notificationService.createNotification(
      userId: studentId,
      title: 'Scholarship Approved!',
      message: 'Congratulations! You have been awarded a ${scholarship.typeDisplay}. '
          '${depositRequired > 0 ? "Please pay the deposit of \$${depositRequired.toStringAsFixed(2)} to secure your scholarship." : ""}',
      type: 'scholarship',
    );
    
    return scholarship.copyWith(id: docRef.id);
  }

  /// Record deposit payment
  Future<void> recordDepositPayment({
    required String scholarshipId,
    required double amount,
    required String transactionId,
  }) async {
    final scholarship = await getScholarshipById(scholarshipId);
    
    if (scholarship == null) {
      throw Exception('Scholarship not found');
    }
    
    final newDepositPaid = scholarship.depositPaid + amount;
    final isFullyPaid = newDepositPaid >= scholarship.depositRequired;
    
    await _firestore.collection('scholarships').doc(scholarshipId).update({
      'depositPaid': newDepositPaid,
      'depositPaidAt': FieldValue.serverTimestamp(),
      'depositTransactionId': transactionId,
      'depositStatus': isFullyPaid 
          ? ScholarshipDepositStatus.deposited.toString().split('.').last
          : ScholarshipDepositStatus.pending.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Notify student
    await _notificationService.createNotification(
      userId: scholarship.studentId,
      title: isFullyPaid ? 'Deposit Paid!' : 'Partial Deposit Received',
      message: isFullyPaid
          ? 'Your scholarship deposit of \$${scholarship.depositRequired.toStringAsFixed(2)} has been received. Your scholarship is now active!'
          : 'Partial deposit of \$${amount.toStringAsFixed(2)} received. Remaining: \$${(scholarship.depositRequired - newDepositPaid).toStringAsFixed(2)}',
      type: 'scholarship',
    );
  }

  /// Process graduation and release/forfeit deposit
  Future<void> processGraduation({
    required String scholarshipId,
    required double finalGPA,
    required String finalGrade,
    required String processedById,
  }) async {
    final scholarship = await getScholarshipById(scholarshipId);
    
    if (scholarship == null) {
      throw Exception('Scholarship not found');
    }
    
    if (scholarship.depositStatus != ScholarshipDepositStatus.deposited) {
      throw Exception('Deposit not yet paid');
    }
    
    final now = DateTime.now();
    final meetsRequirement = ScholarshipModel.checkMinimumRequirement(
      finalGPA,
      finalGrade,
      scholarship.minimumGradeRequired,
      scholarship.minimumLetterGrade,
    );
    
    if (meetsRequirement) {
      // Release deposit
      await _firestore.collection('scholarships').doc(scholarshipId).update({
        'hasGraduated': true,
        'graduationDate': Timestamp.fromDate(now),
        'finalGPA': finalGPA,
        'finalGrade': finalGrade,
        'meetsMinimumRequirement': true,
        'depositStatus': ScholarshipDepositStatus.released.toString().split('.').last,
        'releasedAt': Timestamp.fromDate(now),
        'releasedBy': processedById,
        'releasedAmount': scholarship.depositPaid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Notify student of deposit release
      await _notificationService.createNotification(
        userId: scholarship.studentId,
        title: 'Deposit Released!',
        message: 'Congratulations on graduating! Your deposit of \$${scholarship.depositPaid.toStringAsFixed(2)} has been released.',
        type: 'scholarship',
      );
    } else {
      // Forfeit deposit
      await _firestore.collection('scholarships').doc(scholarshipId).update({
        'hasGraduated': true,
        'graduationDate': Timestamp.fromDate(now),
        'finalGPA': finalGPA,
        'finalGrade': finalGrade,
        'meetsMinimumRequirement': false,
        'depositStatus': ScholarshipDepositStatus.forfeited.toString().split('.').last,
        'forfeitedAt': Timestamp.fromDate(now),
        'forfeitedBy': processedById,
        'forfeitureReason': 'Did not meet minimum grade requirement (${scholarship.minimumLetterGrade} or ${scholarship.minimumGradeRequired} GPA)',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Notify student of deposit forfeiture
      await _notificationService.createNotification(
        userId: scholarship.studentId,
        title: 'Deposit Forfeited',
        message: 'Your scholarship deposit has been forfeited as you did not meet the minimum grade requirement.',
        type: 'scholarship',
      );
    }
  }

  /// Get scholarship by ID
  Future<ScholarshipModel?> getScholarshipById(String scholarshipId) async {
    final doc = await _firestore.collection('scholarships').doc(scholarshipId).get();
    
    if (doc.exists) {
      return ScholarshipModel.fromFirestore(doc);
    }
    
    return null;
  }

  /// Get student's scholarships
  Stream<List<ScholarshipModel>> getStudentScholarships(String studentId) {
    return _firestore
        .collection('scholarships')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScholarshipModel.fromFirestore(doc))
            .toList());
  }

  /// Get all scholarships (admin view)
  Stream<List<ScholarshipModel>> getAllScholarships({ScholarshipDepositStatus? status}) {
    Query<Map<String, dynamic>> query = _firestore.collection('scholarships');
    
    if (status != null) {
      query = query.where('depositStatus', isEqualTo: status.toString().split('.').last);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScholarshipModel.fromFirestore(doc))
            .toList());
  }

  /// Get scholarships for a course
  Stream<List<ScholarshipModel>> getCourseScholarships(String courseId) {
    return _firestore
        .collection('scholarships')
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScholarshipModel.fromFirestore(doc))
            .toList());
  }

  /// Check if student has active scholarship for course
  Future<ScholarshipModel?> getActiveScholarship(String studentId, String courseId) async {
    final snapshot = await _firestore
        .collection('scholarships')
        .where('studentId', isEqualTo: studentId)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return ScholarshipModel.fromFirestore(snapshot.docs.first);
    }
    
    return null;
  }

  /// Get scholarship statistics
  Future<Map<String, dynamic>> getScholarshipStats() async {
    final allScholarships = await _firestore.collection('scholarships').get();
    
    int total = allScholarships.docs.length;
    int pending = 0;
    int deposited = 0;
    int released = 0;
    int forfeited = 0;
    double totalDepositsPaid = 0.0;
    double totalReleased = 0.0;
    double totalForfeited = 0.0;
    
    for (final doc in allScholarships.docs) {
      final data = doc.data();
      final status = data['depositStatus'] ?? '';
      final depositPaid = (data['depositPaid'] ?? 0).toDouble();
      
      if (status == 'pending') pending++;
      if (status == 'deposited') deposited++;
      if (status == 'released') {
        released++;
        totalReleased += depositPaid;
      }
      if (status == 'forfeited') {
        forfeited++;
        totalForfeited += depositPaid;
      }
      
      totalDepositsPaid += depositPaid;
    }
    
    return {
      'total': total,
      'pending': pending,
      'deposited': deposited,
      'released': released,
      'forfeited': forfeited,
      'totalDepositsPaid': totalDepositsPaid,
      'totalReleased': totalReleased,
      'totalForfeited': totalForfeited,
    };
  }

  /// Update scholarship details
  Future<void> updateScholarship({
    required String scholarshipId,
    double? minimumGradeRequired,
    String? minimumLetterGrade,
    String? remarks,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (minimumGradeRequired != null) {
      updates['minimumGradeRequired'] = minimumGradeRequired;
    }
    if (minimumLetterGrade != null) {
      updates['minimumLetterGrade'] = minimumLetterGrade;
    }
    if (remarks != null) {
      updates['remarks'] = remarks;
    }
    
    await _firestore.collection('scholarships').doc(scholarshipId).update(updates);
  }

  /// Get pending deposits (admin view)
  Future<List<ScholarshipModel>> getPendingDeposits() async {
    final snapshot = await _firestore
        .collection('scholarships')
        .where('depositStatus', isEqualTo: ScholarshipDepositStatus.pending.toString().split('.').last)
        .orderBy('createdAt')
        .get();
    
    return snapshot.docs
        .map((doc) => ScholarshipModel.fromFirestore(doc))
        .toList();
  }

  /// Get ready for graduation (deposits paid, not yet graduated)
  Future<List<ScholarshipModel>> getReadyForGraduation() async {
    final snapshot = await _firestore
        .collection('scholarships')
        .where('depositStatus', isEqualTo: ScholarshipDepositStatus.deposited.toString().split('.').last)
        .where('hasGraduated', isEqualTo: false)
        .orderBy('createdAt')
        .get();
    
    return snapshot.docs
        .map((doc) => ScholarshipModel.fromFirestore(doc))
        .toList();
  }
}
