import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import 'notification_service.dart';
import 'achievement_service.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // Create new assignment
  Future<String> createAssignment({
    required String courseId,
    required String courseName,
    required String lecturerId,
    required String lecturerName,
    required String title,
    required String description,
    required DateTime dueDate,
    int totalPoints = 100,
    File? attachmentFile,
    bool publishImmediately = true,
  }) async {
    try {
      String? attachmentUrl;
      
      // Upload attachment if provided
      if (attachmentFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${attachmentFile.path.split('/').last}';
        final ref = _storage.ref().child('assignments/$courseId/$fileName');
        await ref.putFile(attachmentFile);
        attachmentUrl = await ref.getDownloadURL();
      }

      final assignment = AssignmentModel(
        id: '',
        courseId: courseId,
        courseName: courseName,
        lecturerId: lecturerId,
        lecturerName: lecturerName,
        title: title,
        description: description,
        attachmentUrl: attachmentUrl,
        dueDate: dueDate,
        totalPoints: totalPoints,
        createdAt: DateTime.now(),
        isPublished: publishImmediately,
      );

      final docRef = await _firestore.collection('assignments').add(assignment.toFirestore());

      // Notify enrolled students if published immediately
      if (publishImmediately) {
        await _notificationService.notifyCourseStudents(
          courseId: courseId,
          title: 'New Assignment',
          message: '$lecturerName posted "$title" in $courseName',
          type: 'assignment',
          actionUrl: '/assignment/${docRef.id}',
        );
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create assignment: $e');
    }
  }

  // Get assignments for a course
  Stream<List<AssignmentModel>> getAssignmentsByCourse(String courseId) {
    return _firestore
        .collection('assignments')
        .where('courseId', isEqualTo: courseId)
        .where('isPublished', isEqualTo: true)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssignmentModel.fromFirestore(doc))
            .toList());
  }

  // Get assignments created by lecturer
  Stream<List<AssignmentModel>> getAssignmentsByLecturer(String lecturerId) {
    return _firestore
        .collection('assignments')
        .where('lecturerId', isEqualTo: lecturerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AssignmentModel.fromFirestore(doc))
            .toList());
  }

  // Submit assignment
  Future<String> submitAssignment({
    required String assignmentId,
    required String courseId,
    required String courseName,
    required String studentId,
    required String studentName,
    required String studentEmail,
    String? textSubmission,
    File? submissionFile,
  }) async {
    try {
      String? fileUrl;

      // Upload submission file if provided
      if (submissionFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${studentId}_${submissionFile.path.split('/').last}';
        final ref = _storage.ref().child('submissions/$assignmentId/$fileName');
        await ref.putFile(submissionFile);
        fileUrl = await ref.getDownloadURL();
      }

      final submission = SubmissionModel(
        id: '',
        assignmentId: assignmentId,
        type: SubmissionType.assignment,
        courseId: courseId,
        courseName: courseName,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        textSubmission: textSubmission,
        fileUrl: fileUrl,
        submittedAt: DateTime.now(),
        status: SubmissionStatus.submitted,
      );

      final docRef = await _firestore.collection('submissions').add(submission.toFirestore());

      // Update assignment submission count
      await _firestore.collection('assignments').doc(assignmentId).update({
        'submissionCount': FieldValue.increment(1),
      });

      // Get assignment details to notify lecturer
      final assignmentDoc = await _firestore.collection('assignments').doc(assignmentId).get();
      if (assignmentDoc.exists) {
        final assignment = AssignmentModel.fromFirestore(assignmentDoc);
        await _notificationService.createNotification(
          userId: assignment.lecturerId,
          title: 'New Submission',
          message: '$studentName submitted "${assignment.title}"',
          type: 'assignment',
          actionUrl: '/submission/${docRef.id}',
        );
      }

      // Trigger achievement check for assignment submission
      unawaited(AchievementService().onAssignmentSubmitted(studentId));

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit assignment: $e');
    }
  }
  Stream<List<SubmissionModel>> getSubmissionsByAssignment(String assignmentId) {
    return _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .where('type', isEqualTo: 'assignment')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubmissionModel.fromFirestore(doc))
            .toList());
  }

  // Get student's submission for an assignment
  Future<SubmissionModel?> getStudentSubmission(String assignmentId, String studentId) async {
    final snapshot = await _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .where('studentId', isEqualTo: studentId)
        .where('type', isEqualTo: 'assignment')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return SubmissionModel.fromFirestore(snapshot.docs.first);
  }

  // Grade submission
  Future<void> gradeSubmission({
    required String submissionId,
    required double score,
    required double totalPoints,
    required String grade,
    required String lecturerId,
    required String lecturerName,
    String? feedback,
  }) async {
    try {
      await _firestore.collection('submissions').doc(submissionId).update({
        'score': score,
        'totalPoints': totalPoints,
        'grade': grade,
        'feedback': feedback,
        'gradedAt': Timestamp.now(),
        'gradedByLecturerId': lecturerId,
        'gradedByLecturerName': lecturerName,
        'status': 'graded',
      });

      // Get submission details to notify student
      final submissionDoc = await _firestore.collection('submissions').doc(submissionId).get();
      if (submissionDoc.exists) {
        final submission = SubmissionModel.fromFirestore(submissionDoc);
        await _notificationService.createNotification(
          userId: submission.studentId,
          title: 'Assignment Graded',
          message: 'Your submission for "${submission.courseName}" has been graded: $grade',
          type: 'grading',
          actionUrl: '/submission/$submissionId',
        );
      }
    } catch (e) {
      throw Exception('Failed to grade submission: $e');
    }
  }

  // Delete assignment
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _firestore.collection('assignments').doc(assignmentId).delete();
      
      // Delete all submissions for this assignment
      final submissions = await _firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();
      
      for (var doc in submissions.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete assignment: $e');
    }
  }

  // Update assignment
  Future<void> updateAssignment({
    required String assignmentId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? totalPoints,
    bool? isPublished,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);
      if (totalPoints != null) updates['totalPoints'] = totalPoints;
      if (isPublished != null) updates['isPublished'] = isPublished;

      if (updates.isNotEmpty) {
        await _firestore.collection('assignments').doc(assignmentId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update assignment: $e');
    }
  }
}
