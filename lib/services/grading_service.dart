import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade_model.dart';
import '../models/submission_model.dart';
import 'notification_service.dart';
import 'certificate_service.dart';

class GradingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final CertificateService _certificateService = CertificateService();

  // Assign grade to student for a course
  Future<String> assignGrade({
    required String studentId,
    required String studentName,
    required String studentEmail,
    required String courseId,
    required String courseName,
    required LetterGrade grade,
    required double numericScore,
    required String lecturerId,
    required String lecturerName,
    required String semester,
    required bool isPaidCourse,
    String? comments,
  }) async {
    try {
      // Calculate EMC reward based on grade
      final emcReward = GradeModel.calculateEmcReward(grade, isPaidCourse);

      final gradeModel = GradeModel(
        id: '',
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        courseId: courseId,
        courseName: courseName,
        grade: grade,
        numericScore: numericScore,
        emcReward: emcReward,
        lecturerId: lecturerId,
        lecturerName: lecturerName,
        gradedAt: DateTime.now(),
        semester: semester,
        isRedeemed: false,
        comments: comments,
      );

      final docRef = await _firestore.collection('grades').add(gradeModel.toFirestore());

      // Update student's EMC balance (add unredeemed EMC)
      await _firestore.collection('users').doc(studentId).update({
        'unredeemedEMC': FieldValue.increment(emcReward),
      });

      // Notify student about grade and EMC reward
      await _notificationService.createNotification(
        userId: studentId,
        title: 'Grade Published',
        message: 'You earned a ${grade.toString().split('.').last} in $courseName! EMC Reward: ${emcReward.toStringAsFixed(0)} EMC',
        type: 'grading',
        actionUrl: '/grade/${docRef.id}',
      );

      // Auto-issue certificate for passing grades (C and above)
      try {
        await _certificateService.autoIssueCertificateOnGrade(gradeModel);
      } catch (e) {
        print('Failed to auto-issue certificate: $e');
        // Don't fail the grade assignment if certificate issuance fails
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to assign grade: $e');
    }
  }

  // Auto-grade from submission (convert numeric score to letter grade)
  Future<String> autoGradeFromSubmission({
    required String submissionId,
    required String lecturerId,
    required String lecturerName,
    required String semester,
    required bool isPaidCourse,
    String? comments,
  }) async {
    try {
      // Get submission
      final submissionDoc = await _firestore.collection('submissions').doc(submissionId).get();
      if (!submissionDoc.exists) {
        throw Exception('Submission not found');
      }

      final submission = SubmissionModel.fromFirestore(submissionDoc);
      
      if (submission.score == null || submission.totalPoints == null) {
        throw Exception('Submission has no score');
      }

      // Calculate percentage and convert to letter grade
      final percentage = (submission.score! / submission.totalPoints!) * 100;
      final letterGrade = GradeModel.numericToLetterGrade(percentage);

      // Assign grade
      return await assignGrade(
        studentId: submission.studentId,
        studentName: submission.studentName,
        studentEmail: submission.studentEmail,
        courseId: submission.courseId,
        courseName: submission.courseName,
        grade: letterGrade,
        numericScore: percentage,
        lecturerId: lecturerId,
        lecturerName: lecturerName,
        semester: semester,
        isPaidCourse: isPaidCourse,
        comments: comments,
      );
    } catch (e) {
      throw Exception('Failed to auto-grade: $e');
    }
  }

  // Get grades for a student
  Stream<List<GradeModel>> getStudentGrades(String studentId) {
    return _firestore
        .collection('grades')
        .where('studentId', isEqualTo: studentId)
        .orderBy('gradedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GradeModel.fromFirestore(doc))
            .toList());
  }

  // Get grades for a course
  Stream<List<GradeModel>> getCourseGrades(String courseId) {
    return _firestore
        .collection('grades')
        .where('courseId', isEqualTo: courseId)
        .orderBy('gradedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GradeModel.fromFirestore(doc))
            .toList());
  }

  // Get student's grade for a specific course
  Future<GradeModel?> getStudentCourseGrade(String studentId, String courseId) async {
    final snapshot = await _firestore
        .collection('grades')
        .where('studentId', isEqualTo: studentId)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return GradeModel.fromFirestore(snapshot.docs.first);
  }

  // Calculate GPA for student
  Future<double> calculateGPA(String studentId, {String? semester}) async {
    try {
      Query query = _firestore
          .collection('grades')
          .where('studentId', isEqualTo: studentId);

      if (semester != null) {
        query = query.where('semester', isEqualTo: semester);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return 0.0;

      final grades = snapshot.docs
          .map((doc) => GradeModel.fromFirestore(doc))
          .toList();

      // Calculate GPA (A=4.0, B=3.0, C=2.0, D=1.0, E=0.5, F=0.0)
      double totalPoints = 0;
      for (var grade in grades) {
        switch (grade.grade) {
          case LetterGrade.A:
            totalPoints += 4.0;
            break;
          case LetterGrade.B:
            totalPoints += 3.0;
            break;
          case LetterGrade.C:
            totalPoints += 2.0;
            break;
          case LetterGrade.D:
            totalPoints += 1.0;
            break;
          case LetterGrade.E:
            totalPoints += 0.5;
            break;
          case LetterGrade.F:
            totalPoints += 0.0;
            break;
        }
      }

      return totalPoints / grades.length;
    } catch (e) {
      throw Exception('Failed to calculate GPA: $e');
    }
  }

  // Get total unredeemed EMC for student
  Future<double> getTotalUnredeemedEMC(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('grades')
          .where('studentId', isEqualTo: studentId)
          .where('isRedeemed', isEqualTo: false)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        final grade = GradeModel.fromFirestore(doc);
        total += grade.emcReward;
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate unredeemed EMC: $e');
    }
  }

  // Redeem EMC rewards
  Future<void> redeemEMCRewards(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('grades')
          .where('studentId', isEqualTo: studentId)
          .where('isRedeemed', isEqualTo: false)
          .get();

      double totalReward = 0;
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        final grade = GradeModel.fromFirestore(doc);
        totalReward += grade.emcReward;
        
        // Mark as redeemed
        batch.update(doc.reference, {
          'isRedeemed': true,
          'redeemedAt': Timestamp.now(),
        });
      }

      // Update user's EMC balance
      final userRef = _firestore.collection('users').doc(studentId);
      batch.update(userRef, {
        'emcBalance': FieldValue.increment(totalReward),
        'unredeemedEMC': FieldValue.increment(-totalReward),
      });

      await batch.commit();

      // Notify student
      await _notificationService.createNotification(
        userId: studentId,
        title: 'EMC Redeemed',
        message: 'Successfully redeemed ${totalReward.toStringAsFixed(0)} EMC to your wallet!',
        type: 'payment',
      );
    } catch (e) {
      throw Exception('Failed to redeem EMC: $e');
    }
  }

  // Update grade
  Future<void> updateGrade({
    required String gradeId,
    LetterGrade? grade,
    double? numericScore,
    String? comments,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (grade != null) {
        updates['grade'] = grade.toString().split('.').last;
        
        // Recalculate EMC reward if grade changes
        final gradeDoc = await _firestore.collection('grades').doc(gradeId).get();
        if (gradeDoc.exists) {
          final currentGrade = GradeModel.fromFirestore(gradeDoc);
          final courseDoc = await _firestore.collection('courses').doc(currentGrade.courseId).get();
          final isPaid = courseDoc.exists ? (courseDoc.data()?['price'] ?? 0) > 0 : false;
          final newReward = GradeModel.calculateEmcReward(grade, isPaid);
          
          // Update unredeemed balance if not yet redeemed
          if (!currentGrade.isRedeemed) {
            final difference = newReward - currentGrade.emcReward;
            await _firestore.collection('users').doc(currentGrade.studentId).update({
              'unredeemedEMC': FieldValue.increment(difference),
            });
          }
          
          updates['emcReward'] = newReward;
        }
      }
      
      if (numericScore != null) updates['numericScore'] = numericScore;
      if (comments != null) updates['comments'] = comments;

      if (updates.isNotEmpty) {
        await _firestore.collection('grades').doc(gradeId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update grade: $e');
    }
  }

  // Delete grade
  Future<void> deleteGrade(String gradeId) async {
    try {
      // Get grade to adjust EMC balance
      final gradeDoc = await _firestore.collection('grades').doc(gradeId).get();
      if (gradeDoc.exists) {
        final grade = GradeModel.fromFirestore(gradeDoc);
        
        // Remove unredeemed EMC if not yet redeemed
        if (!grade.isRedeemed) {
          await _firestore.collection('users').doc(grade.studentId).update({
            'unredeemedEMC': FieldValue.increment(-grade.emcReward),
          });
        }
      }

      await _firestore.collection('grades').doc(gradeId).delete();
    } catch (e) {
      throw Exception('Failed to delete grade: $e');
    }
  }
}
