import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_task_model.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'achievement_service.dart';

class DailyTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // ────── Task Definitions ──────

  /// Get all active daily tasks from Firestore
  Stream<List<DailyTaskModel>> getActiveTasks() {
    return _firestore
        .collection('dailyTasks')
        .where('isActive', isEqualTo: true)
        .orderBy('rewardEmc', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyTaskModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Admin: create or update a daily task
  Future<String> upsertTask(DailyTaskModel task) async {
    final data = task.toMap();
    data['isActive'] = true;
    if (task.id.isEmpty) {
      final ref = await _firestore.collection('dailyTasks').add(data);
      return ref.id;
    } else {
      await _firestore.collection('dailyTasks').doc(task.id).set(data, SetOptions(merge: true));
      return task.id;
    }
  }

  /// Admin: delete a task
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('dailyTasks').doc(taskId).delete();
  }

  // ────── User Completions ──────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get all task IDs the user has completed today
  Future<Set<String>> getCompletedTaskIds(String userId) async {
    final today = _todayKey();
    final snapshot = await _firestore
        .collection('userDailyTasks')
        .doc(userId)
        .collection('completions')
        .where('date', isEqualTo: today)
        .get();
    return snapshot.docs.map((doc) => doc['taskId'] as String).toSet();
  }

  /// Stream of today's completion docs for this user
  Stream<Set<String>> watchCompletedTaskIds(String userId) {
    final today = _todayKey();
    return _firestore
        .collection('userDailyTasks')
        .doc(userId)
        .collection('completions')
        .where('date', isEqualTo: today)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['taskId'] as String).toSet());
  }

  /// Complete a task — persists to Firestore, awards EMC
  Future<void> completeTask({
    required String userId,
    required String userEmail,
    required DailyTaskModel task,
    required AuthService authService,
  }) async {
    final today = _todayKey();

    // Idempotency check — don't double-award
    final existing = await _firestore
        .collection('userDailyTasks')
        .doc(userId)
        .collection('completions')
        .where('taskId', isEqualTo: task.id)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return; // Already completed today

    // Record completion
    await _firestore
        .collection('userDailyTasks')
        .doc(userId)
        .collection('completions')
        .add({
      'taskId': task.id,
      'taskTitle': task.title,
      'emcRewarded': task.rewardEmc,
      'date': today,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Award EMC tokens
    await authService.addEmcTokens(
      task.rewardEmc,
      'Daily Task: ${task.title}',
    );

    // In-app notification
    await _notificationService.createNotification(
      userId: userId,
      title: 'Task Completed! +${task.rewardEmc} EMC',
      message: 'You earned ${task.rewardEmc} EMC for completing "${task.title}"',
      type: 'reward',
    );

    // Compute streak and trigger achievement check
    final streak = await _computeStreak(userId);
    unawaited(AchievementService().onDailyTaskCompleted(userId, streak));
  }

  /// Count consecutive days the user has completed at least one task.
  Future<int> _computeStreak(String userId) async {
    int streak = 0;
    DateTime day = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final snap = await _firestore
          .collection('userDailyTasks')
          .doc(userId)
          .collection('completions')
          .where('date', isEqualTo: key)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Total EMC earned from daily tasks today
  Future<int> getTodayEarnings(String userId) async {
    final today = _todayKey();
    final snapshot = await _firestore
        .collection('userDailyTasks')
        .doc(userId)
        .collection('completions')
        .where('date', isEqualTo: today)
        .get();
    return snapshot.docs.fold<int>(
      0,
      (sum, doc) => sum + ((doc['emcRewarded'] as num?)?.toInt() ?? 0),
    );
  }

  /// Seed the default daily tasks to Firestore (call once or from admin)
  Future<void> seedDefaultTasks() async {
    final existing = await _firestore
        .collection('dailyTasks')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return; // Already seeded

    final defaults = [
      {
        'title': 'Complete a Lesson',
        'description': 'Watch or read any course material today',
        'rewardEmc': 25,
        'category': 'learning',
        'iconName': 'school',
        'isActive': true,
        'isMockData': true,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      },
      {
        'title': 'Submit an Assignment',
        'description': 'Submit any pending assignment before the deadline',
        'rewardEmc': 20,
        'category': 'learning',
        'iconName': 'assignment_turned_in',
        'isActive': true,
        'isMockData': true,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      },
      {
        'title': 'Attend a Live Class',
        'description': 'Join any live class session today',
        'rewardEmc': 15,
        'category': 'learning',
        'iconName': 'video_call',
        'isActive': true,
        'isMockData': true,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      },
      {
        'title': 'Post in the Forum',
        'description': 'Create a post or reply in the student forum',
        'rewardEmc': 10,
        'category': 'social',
        'iconName': 'forum',
        'isActive': true,
        'isMockData': true,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      },
      {
        'title': 'Refer a Friend',
        'description': 'Share your referral code with a friend',
        'rewardEmc': 50,
        'category': 'social',
        'iconName': 'people',
        'isActive': true,
        'isMockData': true,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      },
      {
        'title': 'Read a Blog Article',
        'description': 'Read any article from the Blog & News section',
        'rewardEmc': 5,
        'category': 'learning',
        'iconName': 'article',
        'isActive': true,
        'isMockData': true,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      },
      {
        'title': 'Study for 30 Minutes',
        'description': 'Spend at least 30 minutes on course content',
        'rewardEmc': 15,
        'category': 'achievement',
        'iconName': 'timer',
        'isActive': true,
        'isMockData': true,
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      },
    ];

    final batch = _firestore.batch();
    for (final task in defaults) {
      final ref = _firestore.collection('dailyTasks').doc();
      batch.set(ref, task);
    }
    await batch.commit();
  }
}
