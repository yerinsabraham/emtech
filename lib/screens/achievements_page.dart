import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final uid = authService.userModel?.uid ?? '';
    final achievementService = AchievementService();

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: uid.isEmpty
          ? const Center(child: Text('Please log in', style: TextStyle(color: Colors.white54)))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: achievementService.getUserAchievementsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];
                final unlockedCount = items
                    .where((m) => (m['achievement'] as UserAchievement).unlocked)
                    .length;
                final totalEMC = items
                    .where((m) => (m['achievement'] as UserAchievement).unlocked)
                    .fold<int>(0, (sum, m) => sum + (m['def'] as AchievementDef).emcReward);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary banner
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your Achievements',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$unlockedCount / ${items.length} Unlocked',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: items.isEmpty ? 0 : unlockedCount / items.length,
                                        minHeight: 8,
                                        backgroundColor: Colors.white24,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                children: [
                                  const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 32),
                                  const SizedBox(height: 4),
                                  Text(
                                    '+$totalEMC EMC',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
                                    'Earned',
                                    style: TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Unlocked section
                        if (unlockedCount > 0) ...[
                          _sectionHeader('Unlocked 🏅'),
                          ...items
                              .where((m) => (m['achievement'] as UserAchievement).unlocked)
                              .map((m) => _AchievementTile(
                                    def: m['def'] as AchievementDef,
                                    achievement: m['achievement'] as UserAchievement,
                                  )),
                          const SizedBox(height: 16),
                        ],

                        // Locked section
                        _sectionHeader('Locked 🔒'),
                        ...items
                            .where((m) => !(m['achievement'] as UserAchievement).unlocked)
                            .map((m) => _AchievementTile(
                                  def: m['def'] as AchievementDef,
                                  achievement: m['achievement'] as UserAchievement,
                                )),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementDef def;
  final UserAchievement achievement;

  const _AchievementTile({required this.def, required this.achievement});

  Color get _accentColor {
    try {
      final hex = def.colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasProgress = def.id == 'five_enrollments' ||
        def.id == 'forum_contributor' ||
        def.id == 'streak_7' ||
        def.id == 'master_graduate';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: achievement.unlocked
            ? _accentColor.withOpacity(0.12)
            : const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: achievement.unlocked ? _accentColor.withOpacity(0.4) : const Color(0xFF1E2D4A),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: achievement.unlocked
                  ? _accentColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: achievement.unlocked
                  ? Text(def.icon, style: const TextStyle(fontSize: 26))
                  : const Icon(Icons.lock, color: Colors.white24, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: TextStyle(
                    color: achievement.unlocked ? Colors.white : Colors.white54,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  def.description,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                if (hasProgress && !achievement.unlocked) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.targetProgress > 0
                          ? achievement.currentProgress / achievement.targetProgress
                          : 0,
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${achievement.currentProgress} / ${achievement.targetProgress}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
                if (achievement.unlocked && achievement.unlockedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Unlocked ${DateFormat('MMM d, yyyy').format(achievement.unlockedAt!)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // EMC badge
          Column(
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16),
              Text(
                '+${def.emcReward}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

