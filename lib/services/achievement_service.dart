import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

// ─────────────────────────────────────────────────────────
// Achievement definition
// ─────────────────────────────────────────────────────────

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji
  final int emcReward;
  final String colorHex;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.emcReward,
    required this.colorHex,
  });
}

// ─────────────────────────────────────────────────────────
// All achievement definitions (static catalogue)
// ─────────────────────────────────────────────────────────

class AchievementCatalogue {
  static const List<AchievementDef> all = [
    AchievementDef(
      id: 'first_enrollment',
      title: 'First Step',
      description: 'Enroll in your first course',
      icon: '🎓',
      emcReward: 50,
      colorHex: '#FFA500',
    ),
    AchievementDef(
      id: 'five_enrollments',
      title: 'Knowledge Seeker',
      description: 'Enroll in 5 different courses',
      icon: '📚',
      emcReward: 200,
      colorHex: '#3B82F6',
    ),
    AchievementDef(
      id: 'first_assignment',
      title: 'Ready to Learn',
      description: 'Submit your first assignment',
      icon: '📝',
      emcReward: 50,
      colorHex: '#8B5CF6',
    ),
    AchievementDef(
      id: 'perfect_assignment',
      title: 'Perfectionist',
      description: 'Score 100% on an assignment',
      icon: '⭐',
      emcReward: 100,
      colorHex: '#FFD700',
    ),
    AchievementDef(
      id: 'first_exam',
      title: 'Test Taker',
      description: 'Complete your first exam',
      icon: '✅',
      emcReward: 50,
      colorHex: '#22C55E',
    ),
    AchievementDef(
      id: 'exam_master',
      title: 'Exam Master',
      description: 'Score 90%+ on an exam',
      icon: '🏆',
      emcReward: 150,
      colorHex: '#F59E0B',
    ),
    AchievementDef(
      id: 'forum_contributor',
      title: 'Community Hero',
      description: 'Post 5 replies in the forum',
      icon: '💬',
      emcReward: 100,
      colorHex: '#06B6D4',
    ),
    AchievementDef(
      id: 'streak_7',
      title: '7-Day Streak',
      description: 'Complete daily tasks 7 days in a row',
      icon: '🔥',
      emcReward: 150,
      colorHex: '#FF5252',
    ),
    AchievementDef(
      id: 'first_paid_course',
      title: 'Premium Member',
      description: 'Purchase your first premium course',
      icon: '💎',
      emcReward: 100,
      colorHex: '#EC4899',
    ),
    AchievementDef(
      id: 'first_stake',
      title: 'Staker',
      description: 'Stake EMC tokens for the first time',
      icon: '🔒',
      emcReward: 100,
      colorHex: '#10B981',
    ),
    AchievementDef(
      id: 'rising_star',
      title: 'Rising Star',
      description: 'Earn 5,000 EMC in total',
      icon: '🌟',
      emcReward: 200,
      colorHex: '#3B82F6',
    ),
    AchievementDef(
      id: 'first_certificate',
      title: 'Graduate!',
      description: 'Earn your first certificate',
      icon: '🎖️',
      emcReward: 300,
      colorHex: '#D4AF37',
    ),
    AchievementDef(
      id: 'master_graduate',
      title: 'Master Graduate',
      description: 'Earn 3 certificates with distinction',
      icon: '👑',
      emcReward: 500,
      colorHex: '#8B5CF6',
    ),
  ];

  static AchievementDef? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────
// User achievement record (stored in Firestore)
// ─────────────────────────────────────────────────────────

class UserAchievement {
  final String id;
  final bool unlocked;
  final DateTime? unlockedAt;
  final int currentProgress; // for multi-step achievements
  final int targetProgress;  // 0 means single-event (no progress bar)

  const UserAchievement({
    required this.id,
    required this.unlocked,
    this.unlockedAt,
    this.currentProgress = 0,
    this.targetProgress = 0,
  });

  factory UserAchievement.fromMap(Map<String, dynamic> map, String id) {
    return UserAchievement(
      id: id,
      unlocked: map['unlocked'] ?? false,
      unlockedAt: map['unlockedAt'] != null
          ? (map['unlockedAt'] as Timestamp).toDate()
          : null,
      currentProgress: map['currentProgress'] ?? 0,
      targetProgress: map['targetProgress'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'unlocked': unlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
    };
  }
}

// ─────────────────────────────────────────────────────────
// AchievementService
// ─────────────────────────────────────────────────────────

class AchievementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notif = NotificationService();

  DocumentReference _userDoc(String uid) => _db.collection('userAchievements').doc(uid);

  /// Stream of user's achievements merged with catalogue
  Stream<List<Map<String, dynamic>>> getUserAchievementsStream(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      final data = (snap.data() as Map<String, dynamic>?) ?? {};
      return AchievementCatalogue.all.map((def) {
        final raw = data[def.id] as Map<String, dynamic>?;
        final ua = raw != null
            ? UserAchievement.fromMap(raw, def.id)
            : UserAchievement(id: def.id, unlocked: false, targetProgress: _targetFor(def.id));
        return {
          'def': def,
          'achievement': ua,
        };
      }).toList();
    });
  }

  int _targetFor(String id) {
    switch (id) {
      case 'five_enrollments':
        return 5;
      case 'forum_contributor':
        return 5;
      case 'streak_7':
        return 7;
      case 'master_graduate':
        return 3;
      default:
        return 0;
    }
  }

  // ── Trigger methods ───────────────────────────────────────

  Future<void> onEnrollment(String uid, {bool isPaid = false}) async {
    await _singleEvent(uid, 'first_enrollment');
    await _incrementProgress(uid, 'five_enrollments', 5);
    if (isPaid) await _singleEvent(uid, 'first_paid_course');
  }

  Future<void> onAssignmentSubmitted(String uid) async {
    await _singleEvent(uid, 'first_assignment');
  }

  Future<void> onAssignmentGraded(String uid, double score) async {
    if (score >= 100) await _singleEvent(uid, 'perfect_assignment');
  }

  Future<void> onExamCompleted(String uid, double scorePercent) async {
    await _singleEvent(uid, 'first_exam');
    if (scorePercent >= 90) await _singleEvent(uid, 'exam_master');
  }

  Future<void> onForumReply(String uid) async {
    await _incrementProgress(uid, 'forum_contributor', 5);
  }

  Future<void> onDailyTaskCompleted(String uid, int streak) async {
    if (streak >= 7) await _singleEvent(uid, 'streak_7');
  }

  Future<void> onStake(String uid) async {
    await _singleEvent(uid, 'first_stake');
  }

  Future<void> onEMCEarned(String uid, double totalEarned) async {
    if (totalEarned >= 5000) await _singleEvent(uid, 'rising_star');
  }

  Future<void> onCertificateIssued(String uid, int totalCerts) async {
    await _singleEvent(uid, 'first_certificate');
    if (totalCerts >= 3) await _incrementProgress(uid, 'master_graduate', 3);
  }

  // ── Internal helpers ─────────────────────────────────────

  /// Award a one-time achievement if not already unlocked
  Future<void> _singleEvent(String uid, String achievementId) async {
    final snap = await _userDoc(uid).get();
    final data = (snap.data() as Map<String, dynamic>?) ?? {};
    final existing = data[achievementId] as Map<String, dynamic>?;
    if (existing != null && (existing['unlocked'] == true)) return;

    await _unlock(uid, achievementId);
  }

  /// Increment progress counter; unlock when it hits [target]
  Future<void> _incrementProgress(String uid, String achievementId, int target) async {
    final snap = await _userDoc(uid).get();
    final data = (snap.data() as Map<String, dynamic>?) ?? {};
    final existing = data[achievementId] as Map<String, dynamic>?;
    if (existing != null && (existing['unlocked'] == true)) return;

    final current = (existing?['currentProgress'] ?? 0) as int;
    final newProgress = current + 1;

    if (newProgress >= target) {
      await _unlock(uid, achievementId, progress: target, target: target);
    } else {
      await _userDoc(uid).set({
        achievementId: {
          'unlocked': false,
          'currentProgress': newProgress,
          'targetProgress': target,
          'unlockedAt': null,
        }
      }, SetOptions(merge: true));
    }
  }

  Future<void> _unlock(String uid, String achievementId, {int? progress, int? target}) async {
    final def = AchievementCatalogue.byId(achievementId);
    if (def == null) return;

    final now = DateTime.now();
    await _userDoc(uid).set({
      achievementId: {
        'unlocked': true,
        'unlockedAt': Timestamp.fromDate(now),
        'currentProgress': progress ?? (target ?? 0),
        'targetProgress': target ?? 0,
      }
    }, SetOptions(merge: true));

    // Award EMC bonus
    if (def.emcReward > 0) {
      await _db.collection('users').doc(uid).update({
        'availableEMC': FieldValue.increment(def.emcReward),
        'emcBalance': FieldValue.increment(def.emcReward),
        'totalEMCEarned': FieldValue.increment(def.emcReward),
      });
    }

    // Notify user
    await _notif.createNotification(
      userId: uid,
      title: '${def.icon} Achievement Unlocked!',
      message: '"${def.title}" — ${def.description}. +${def.emcReward} EMC bonus!',
      type: 'achievement',
      actionUrl: '/achievements',
    );
  }

  /// Unlock an achievement by ID directly (admin / testing utility)
  Future<void> awardAchievement(String uid, String achievementId) =>
      _singleEvent(uid, achievementId);

  /// Get quick count of unlocked achievements
  Future<int> getUnlockedCount(String uid) async {
    final snap = await _userDoc(uid).get();
    final data = (snap.data() as Map<String, dynamic>?) ?? {};
    return data.values
        .whereType<Map>()
        .where((v) => v['unlocked'] == true)
        .length;
  }
}
