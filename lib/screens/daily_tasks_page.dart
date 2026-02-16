import 'package:flutter/material.dart';
import '../models/daily_task_model.dart';
import '../services/mock_data_service.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  List<DailyTaskModel> _tasks = [];
  int _totalEarnedToday = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasks = MockDataService.getMockDailyTasks();
      _totalEarnedToday = _tasks
          .where((task) => task.isCompleted)
          .fold(0, (sum, task) => sum + task.rewardEmc);
    });
  }

  void _completeTask(DailyTaskModel task) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(isCompleted: true);
        _totalEarnedToday += task.rewardEmc;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Earned ${task.rewardEmc} EMC!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incompleteTasks = _tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = _tasks.where((t) => t.isCompleted).toList();
    final possibleEarnings = _tasks.fold(0, (sum, task) => sum + task.rewardEmc);

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Daily Tasks',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            margin: const EdgeInsets.all(18),
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
                        'Today\'s Progress',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_totalEarnedToday / $possibleEarnings EMC',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${completedTasks.length}/${_tasks.length} tasks completed',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Completion',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${(_tasks.isEmpty ? 0 : (completedTasks.length / _tasks.length * 100)).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _tasks.isEmpty ? 0 : completedTasks.length / _tasks.length,
                    backgroundColor: const Color(0xFF1E2D4A),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tasks List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                if (incompleteTasks.isNotEmpty) ...[
                  const Text(
                    'Available Tasks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...incompleteTasks.map((task) => _buildTaskCard(task)),
                ],
                if (completedTasks.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...completedTasks.map((task) => _buildTaskCard(task)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(DailyTaskModel task) {
    final isCompleted = task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted 
            ? const Color(0xFF0E1827).withOpacity(0.5)
            : const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted 
              ? const Color(0xFF1A2940).withOpacity(0.5)
              : const Color(0xFF1E2D4A),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted ? null : () => _completeTask(task),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green.withOpacity(0.2)
                        : _getCategoryColor(task.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : _getTaskIcon(task.iconName),
                    color: isCompleted ? Colors.green : _getCategoryColor(task.category),
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: isCompleted ? Colors.white38 : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          color: isCompleted ? Colors.white24 : Colors.white60,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Reward Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green.withOpacity(0.1)
                        : const Color(0xFFFBBF24).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted 
                          ? Colors.green.withOpacity(0.3)
                          : const Color(0xFFFBBF24).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: isCompleted ? Colors.green : const Color(0xFFFBBF24),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.rewardEmc}',
                        style: TextStyle(
                          color: isCompleted ? Colors.green : const Color(0xFFFBBF24),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'learning':
        return const Color(0xFF3B82F6);
      case 'social':
        return const Color(0xFF8B5CF6);
      case 'achievement':
        return const Color(0xFFFBBF24);
      default:
        return Colors.grey;
    }
  }

  IconData _getTaskIcon(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'assignment_turned_in':
        return Icons.assignment_turned_in;
      case 'video_call':
        return Icons.video_call;
      case 'forum':
        return Icons.forum;
      case 'people':
        return Icons.people;
      case 'article':
        return Icons.article;
      case 'timer':
        return Icons.timer;
      default:
        return Icons.task_alt;
    }
  }
}
