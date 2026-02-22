import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_model.dart';
import '../models/submission_model.dart';
import 'notification_service.dart';
import 'achievement_service.dart';

class ExamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Create new exam
  Future<String> createExam({
    required String courseId,
    required String courseName,
    required String lecturerId,
    required String lecturerName,
    required String title,
    required String description,
    required List<ExamQuestion> questions,
    required int durationMinutes,
    required DateTime scheduledDate,
  }) async {
    try {
      final totalPoints = questions.fold<int>(
        0,
        (sum, question) => sum + question.points,
      );

      final exam = ExamModel(
        id: '',
        courseId: courseId,
        courseName: courseName,
        lecturerId: lecturerId,
        lecturerName: lecturerName,
        title: title,
        description: description,
        questions: questions,
        totalPoints: totalPoints,
        durationMinutes: durationMinutes,
        scheduledDate: scheduledDate,
        status: ExamStatus.draft,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('exams').add(exam.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create exam: $e');
    }
  }

  // Submit exam for admin approval
  Future<void> submitForApproval(String examId) async {
    try {
      await _firestore.collection('exams').doc(examId).update({
        'status': 'pendingApproval',
        'submittedForApprovalAt': Timestamp.now(),
      });

      // Get exam details
      final examDoc = await _firestore.collection('exams').doc(examId).get();
      if (examDoc.exists) {
        final exam = ExamModel.fromFirestore(examDoc);
        
        // Notify all admins
        await _notificationService.notifyByRole(
          role: 'admin',
          title: 'Exam Approval Required',
          message: '${exam.lecturerName} submitted "${exam.title}" for approval in ${exam.courseName}',
          type: 'exam',
          actionUrl: '/exam/$examId/approve',
        );
      }
    } catch (e) {
      throw Exception('Failed to submit exam for approval: $e');
    }
  }

  // Admin approves exam
  Future<void> approveExam({
    required String examId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _firestore.collection('exams').doc(examId).update({
        'status': 'approved',
        'approvedAt': Timestamp.now(),
        'approvedByAdminId': adminId,
        'approvedByAdminName': adminName,
        'rejectionReason': null,
      });

      // Get exam details
      final examDoc = await _firestore.collection('exams').doc(examId).get();
      if (examDoc.exists) {
        final exam = ExamModel.fromFirestore(examDoc);
        
        // Notify lecturer
        await _notificationService.createNotification(
          userId: exam.lecturerId,
          title: 'Exam Approved',
          message: 'Your exam "${exam.title}" has been approved by $adminName',
          type: 'exam',
          actionUrl: '/exam/$examId',
        );

        // Notify enrolled students
        await _notificationService.notifyCourseStudents(
          courseId: exam.courseId,
          title: 'New Exam Available',
          message: '${exam.title} in ${exam.courseName} is now available',
          type: 'exam',
          actionUrl: '/exam/$examId',
        );
      }
    } catch (e) {
      throw Exception('Failed to approve exam: $e');
    }
  }

  // Admin rejects exam
  Future<void> rejectExam({
    required String examId,
    required String adminId,
    required String adminName,
    required String rejectionReason,
  }) async {
    try {
      await _firestore.collection('exams').doc(examId).update({
        'status': 'rejected',
        'approvedByAdminId': adminId,
        'approvedByAdminName': adminName,
        'rejectionReason': rejectionReason,
      });

      // Get exam details
      final examDoc = await _firestore.collection('exams').doc(examId).get();
      if (examDoc.exists) {
        final exam = ExamModel.fromFirestore(examDoc);
        
        // Notify lecturer
        await _notificationService.createNotification(
          userId: exam.lecturerId,
          title: 'Exam Rejected',
          message: 'Your exam "${exam.title}" was rejected. Reason: $rejectionReason',
          type: 'exam',
          actionUrl: '/exam/$examId',
        );
      }
    } catch (e) {
      throw Exception('Failed to reject exam: $e');
    }
  }

  // Get exams by course
  Stream<List<ExamModel>> getExamsByCourse(String courseId) {
    return _firestore
        .collection('exams')
        .where('courseId', isEqualTo: courseId)
        .where('status', whereIn: ['approved', 'published'])
        .orderBy('scheduledDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExamModel.fromFirestore(doc))
            .toList());
  }

  // Get exams by lecturer
  Stream<List<ExamModel>> getExamsByLecturer(String lecturerId) {
    return _firestore
        .collection('exams')
        .where('lecturerId', isEqualTo: lecturerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExamModel.fromFirestore(doc))
            .toList());
  }

  // Get pending exams (for admin)
  Stream<List<ExamModel>> getPendingExams() {
    return _firestore
        .collection('exams')
        .where('status', isEqualTo: 'pendingApproval')
        .orderBy('submittedForApprovalAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExamModel.fromFirestore(doc))
            .toList());
  }

  // Submit exam attempt
  Future<String> submitExamAttempt({
    required String examId,
    required String courseId,
    required String courseName,
    required String studentId,
    required String studentName,
    required String studentEmail,
    required List<int> answers,
  }) async {
    try {
      // Get exam to calculate score
      final examDoc = await _firestore.collection('exams').doc(examId).get();
      if (!examDoc.exists) {
        throw Exception('Exam not found');
      }

      final exam = ExamModel.fromFirestore(examDoc);
      
      // Calculate score
      double score = 0;
      for (int i = 0; i < answers.length && i < exam.questions.length; i++) {
        if (answers[i] == exam.questions[i].correctAnswerIndex) {
          score += exam.questions[i].points;
        }
      }

      final submission = SubmissionModel(
        id: '',
        assignmentId: examId, // Using assignmentId field for examId
        examId: examId,
        type: SubmissionType.exam,
        courseId: courseId,
        courseName: courseName,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        examAnswers: answers,
        submittedAt: DateTime.now(),
        status: SubmissionStatus.graded, // Auto-graded
        score: score,
        totalPoints: exam.totalPoints.toDouble(),
      );

      final docRef = await _firestore.collection('submissions').add(submission.toFirestore());

      // Update exam attempt count
      await _firestore.collection('exams').doc(examId).update({
        'attemptCount': FieldValue.increment(1),
      });

      // Notify lecturer
      await _notificationService.createNotification(
        userId: exam.lecturerId,
        title: 'Exam Completed',
        message: '$studentName completed "${exam.title}" - Score: ${score.toInt()}/${exam.totalPoints}',
        type: 'exam',
        actionUrl: '/submission/${docRef.id}',
      );

      // Notify student with their score
      await _notificationService.createNotification(
        userId: studentId,
        title: 'Exam Submitted',
        message: 'You scored ${score.toInt()}/${exam.totalPoints} on "${exam.title}"',
        type: 'grading',
        actionUrl: '/submission/${docRef.id}',
      );

      // Trigger achievement check for exam completion
      final scorePercent = exam.totalPoints > 0 ? (score / exam.totalPoints) * 100 : 0.0;
      unawaited(AchievementService().onExamCompleted(studentId, scorePercent));

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit exam: $e');
    }
  }

  // Get student's exam attempt
  Future<SubmissionModel?> getStudentExamAttempt(String examId, String studentId) async {
    final snapshot = await _firestore
        .collection('submissions')
        .where('examId', isEqualTo: examId)
        .where('studentId', isEqualTo: studentId)
        .where('type', isEqualTo: 'exam')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return SubmissionModel.fromFirestore(snapshot.docs.first);
  }

  // Update exam
  Future<void> updateExam({
    required String examId,
    String? title,
    String? description,
    List<ExamQuestion>? questions,
    int? durationMinutes,
    DateTime? scheduledDate,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (questions != null) {
        updates['questions'] = questions.map((q) => q.toMap()).toList();
        final totalPoints = questions.fold<int>(
          0,
          (sum, question) => sum + question.points,
        );
        updates['totalPoints'] = totalPoints;
      }
      if (durationMinutes != null) updates['durationMinutes'] = durationMinutes;
      if (scheduledDate != null) updates['scheduledDate'] = Timestamp.fromDate(scheduledDate);

      if (updates.isNotEmpty) {
        await _firestore.collection('exams').doc(examId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update exam: $e');
    }
  }

  // Delete exam
  Future<void> deleteExam(String examId) async {
    try {
      await _firestore.collection('exams').doc(examId).delete();
      
      // Delete all submissions for this exam
      final submissions = await _firestore
          .collection('submissions')
          .where('examId', isEqualTo: examId)
          .get();
      
      for (var doc in submissions.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete exam: $e');
    }
  }
}
