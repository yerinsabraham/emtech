import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    // Mock achievements
    final achievements = [
      {
        'icon': Icons.emoji_events,
        'title': 'First Course',
        'description': 'Complete your first course',
        'unlocked': true,
        'date': '2 weeks ago',
        'color': const Color(0xFFFFA500),
      },
      {
        'icon': Icons.local_fire_department,
        'title': '7 Day Streak',
        'description': 'Learn for 7 consecutive days',
        'unlocked': true,
        'date': '1 week ago',
        'color': const Color(0xFFFF5252),
      },
      {
        'icon': Icons.star,
        'title': 'Perfect Score',
        'description': 'Get 100% on an assignment',
        'unlocked': true,
        'date': '5 days ago',
        'color': const Color(0xFFFFD700),
      },
      {
        'icon': Icons.school,
        'title': 'Knowledge Seeker',
        'description': 'Enroll in 5 different courses',
        'unlocked': false,
        'date': null,
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.workspace_premium,
        'title': 'Premium Member',
        'description': 'Purchase your first premium course',
        'unlocked': true,
        'date': '3 weeks ago',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.people,
        'title': 'Social Learner',
        'description': 'Help 10 students in the forum',
        'unlocked': false,
        'date': null,
        'color': const Color(0xFF22C55E),
      },
      {
        'icon': Icons.trending_up,
        'title': 'Rising Star',
        'description': 'Earn 5000 EMC tokens',
        'unlocked': false,
        'date': null,
        'color': const Color(0xFF06B6D4),
      },
      {
        'icon': Icons.military_tech,
        'title': 'Master Graduate',
        'description': 'Complete 10 courses with distinction',
        'unlocked': false,
        'date': null,
        'color': const Color(0xFFEC4899),
      },
    ];

    final unlockedCount = achievements.where((a) => a['unlocked'] as bool).length;

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
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Progress Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Achievement Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$unlockedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      ' / ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      '${achievements.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${((unlockedCount / achievements.length) * 100).toStringAsFixed(0)}% Complete',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: unlockedCount / achievements.length,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Your Achievements',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Achievements Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _buildAchievementCard(achievement);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final unlocked = achievement['unlocked'] as bool;
    final color = achievement['color'] as Color;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked 
          ? const Color(0xFF111C2F) 
          : const Color(0xFF111C2F).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? color.withOpacity(0.5) : const Color(0xFF1E2D4A),
          width: unlocked ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: unlocked ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement['icon'] as IconData,
              size: 40,
              color: unlocked ? color : Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement['title'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: unlocked ? Colors.white : Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement['description'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: unlocked ? Colors.white54 : Colors.grey.withOpacity(0.5),
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (unlocked && achievement['date'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                achievement['date'],
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (!unlocked)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(
                Icons.lock,
                size: 16,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}
