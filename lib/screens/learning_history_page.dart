import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LearningHistoryPage extends StatelessWidget {
  const LearningHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    // Mock learning history data
    final history = [
      {
        'course': 'Introduction to AI',
        'progress': 75,
        'lastAccessed': '2 hours ago',
        'status': 'In Progress',
        'lessons': 12,
        'completedLessons': 9,
      },
      {
        'course': 'Web Development Basics',
        'progress': 100,
        'lastAccessed': '1 day ago',
        'status': 'Completed',
        'lessons': 20,
        'completedLessons': 20,
      },
      {
        'course': 'Data Structures',
        'progress': 45,
        'lastAccessed': '3 days ago',
        'status': 'In Progress',
        'lessons': 15,
        'completedLessons': 7,
      },
      {
        'course': 'Mobile App Development',
        'progress': 30,
        'lastAccessed': '5 days ago',
        'status': 'In Progress',
        'lessons': 25,
        'completedLessons': 8,
      },
      {
        'course': 'Database Design',
        'progress': 100,
        'lastAccessed': '1 week ago',
        'status': 'Completed',
        'lessons': 10,
        'completedLessons': 10,
      },
    ];

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
          'Learning History',
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
          // Stats Overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111C2F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('5', 'Courses', Icons.school),
                _buildStat('2', 'Completed', Icons.check_circle),
                _buildStat('58h', 'Total Time', Icons.access_time),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Recent Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // History List
          ...history.map((item) => _buildHistoryCard(item)),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final progress = item['progress'] as int;
    final isCompleted = progress >= 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['course'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted 
                    ? const Color(0xFF22C55E).withOpacity(0.2)
                    : const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['status'],
                  style: TextStyle(
                   color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: const Color(0xFF1E2D4A),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$progress%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item['completedLessons']}/${item['lessons']} lessons',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
              Text(
                'Last: ${item['lastAccessed']}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
