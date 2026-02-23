import 'package:flutter/material.dart';
import 'daily_tasks_page.dart';
import 'courses_list_page.dart';
import 'achievements_page.dart';
import 'student_forum_page.dart';

class EarnEmcPage extends StatelessWidget {
  const EarnEmcPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Earn EMC',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A2744), Color(0xFF0F1B30)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.generating_tokens_rounded,
                        color: Color(0xFF3B82F6),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMC Token',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Earn by learning, engaging & contributing',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const _SectionLabel(label: 'Daily Opportunities'),
          const SizedBox(height: 12),

          // Daily Tasks
          _EarnCard(
            icon: Icons.task_alt_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Daily Tasks',
            subtitle: 'Complete bite-sized tasks every day to earn EMC tokens.',
            rewardLabel: 'Up to 50 EMC / day',
            rewardColor: const Color(0xFF10B981),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DailyTasksPage()),
            ),
          ),

          const SizedBox(height: 10),

          // Forum participation
          _EarnCard(
            icon: Icons.forum_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Forum Participation',
            subtitle: 'Post questions, share answers and engage the community.',
            rewardLabel: 'Earn per post & reply',
            rewardColor: const Color(0xFF8B5CF6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentForumPage()),
            ),
          ),

          const SizedBox(height: 24),
          const _SectionLabel(label: 'Learning Rewards'),
          const SizedBox(height: 12),

          // Course enrollment reward
          _EarnCard(
            icon: Icons.school_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Enroll in a Course',
            subtitle:
                'Receive EMC tokens automatically when you enrol in any course.',
            rewardLabel: 'Reward on enrolment',
            rewardColor: const Color(0xFF3B82F6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoursesListPage()),
            ),
          ),

          const SizedBox(height: 10),

          // Course completion reward
          _EarnCard(
            icon: Icons.military_tech_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Complete a Course',
            subtitle:
                'Finish all modules and pass the course exam to unlock your completion reward.',
            rewardLabel: 'Bonus on 100% progress',
            rewardColor: const Color(0xFFF59E0B),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CoursesListPage()),
            ),
          ),

          const SizedBox(height: 10),

          // Achievements
          _EarnCard(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFEC4899),
            title: 'Unlock Achievements',
            subtitle:
                'Hit milestones — first enrolment, streak days, top scorer — to claim achievement bonuses.',
            rewardLabel: 'Milestone bonuses',
            rewardColor: const Color(0xFFEC4899),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsPage()),
            ),
          ),

          const SizedBox(height: 24),
          const _SectionLabel(label: 'Coming Soon'),
          const SizedBox(height: 12),

          // Staking
          _EarnCard(
            icon: Icons.savings_rounded,
            iconColor: const Color(0xFF06B6D4),
            title: 'Stake EMC',
            subtitle:
                'Lock your tokens for a fixed period and earn yield. Longer stakes = higher APY.',
            rewardLabel: 'Yield rewards',
            rewardColor: const Color(0xFF06B6D4),
            comingSoon: true,
            onTap: null,
          ),

          const SizedBox(height: 10),

          // Referral
          _EarnCard(
            icon: Icons.group_add_rounded,
            iconColor: const Color(0xFFFF7849),
            title: 'Refer a Friend',
            subtitle:
                'Invite someone to join emtech. Earn a referral bonus when they complete their first course.',
            rewardLabel: 'Referral bonus',
            rewardColor: const Color(0xFFFF7849),
            comingSoon: true,
            onTap: null,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Earn Card ─────────────────────────────────────────────────────────────────
class _EarnCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String rewardLabel;
  final Color rewardColor;
  final VoidCallback? onTap;
  final bool comingSoon;

  const _EarnCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.rewardLabel,
    required this.rewardColor,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: comingSoon ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1120),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: comingSoon
                  ? Colors.white10
                  : iconColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (comingSoon ? Colors.white24 : iconColor)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: comingSoon ? Colors.white38 : iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color:
                                  comingSoon ? Colors.white38 : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (comingSoon)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Soon',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (!comingSoon)
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 13, color: Colors.white24),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: comingSoon ? Colors.white24 : Colors.white54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (comingSoon ? Colors.white24 : rewardColor)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                              (comingSoon ? Colors.white24 : rewardColor)
                                  .withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        rewardLabel,
                        style: TextStyle(
                          color: comingSoon ? Colors.white24 : rewardColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
