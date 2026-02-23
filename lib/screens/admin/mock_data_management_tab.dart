import 'package:flutter/material.dart';
import '../../services/mock_data_seeder.dart';

class MockDataManagementTab extends StatefulWidget {
  const MockDataManagementTab({super.key});

  @override
  State<MockDataManagementTab> createState() => _MockDataManagementTabState();
}

class _MockDataManagementTabState extends State<MockDataManagementTab> {
  Map<String, int> _counts = {};
  bool _isLoading = true;
  bool _isWorking = false;

  static const _collections = {
    'courses': 'Courses',
    'books': 'Books',
    'dailyTasks': 'Daily Tasks',
    'forumPosts': 'Forum Posts',
    'blogPosts': 'Blog Posts',
  };

  static const _icons = {
    'courses': Icons.school,
    'books': Icons.menu_book,
    'dailyTasks': Icons.task_alt,
    'forumPosts': Icons.forum,
    'blogPosts': Icons.article,
  };

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    try {
      final counts = await MockDataSeeder.getMockCounts();
      if (mounted) setState(() => _counts = counts);
    } catch (e) {
      _showError('Failed to load mock data counts: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seed(String collection, {bool force = false}) async {
    setState(() => _isWorking = true);
    try {
      int seeded = 0;
      switch (collection) {
        case 'courses':
          seeded = await MockDataSeeder.seedCourses(force: force);
          break;
        case 'books':
          seeded = await MockDataSeeder.seedBooks(force: force);
          break;
        case 'dailyTasks':
          seeded = await MockDataSeeder.seedDailyTasks(force: force);
          break;
        case 'forumPosts':
          seeded = await MockDataSeeder.seedForumPosts(force: force);
          break;
        case 'blogPosts':
          seeded = await MockDataSeeder.seedBlogPosts(force: force);
          break;
      }
      final label = _collections[collection] ?? collection;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            seeded == 0
                ? '$label already seeded — use "Force Re-seed" to overwrite.'
                : 'Seeded $seeded $label records.',
          ),
          backgroundColor: seeded == 0 ? Colors.orange : Colors.green,
        ));
      }
    } catch (e) {
      _showError('Seed failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
        await _loadCounts();
      }
    }
  }

  Future<void> _delete(String collection) async {
    final label = _collections[collection] ?? collection;
    final confirmed = await _confirmDialog(
      'Delete Mock $label',
      'This will permanently delete all ${_counts[collection] ?? 0} mock $label documents. This cannot be undone.',
    );
    if (!confirmed) return;

    setState(() => _isWorking = true);
    try {
      final deleted = await MockDataSeeder.deleteMockData(collection);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Deleted $deleted mock $label records.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      _showError('Delete failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
        await _loadCounts();
      }
    }
  }

  Future<void> _seedAll() async {
    setState(() => _isWorking = true);
    try {
      final results = await MockDataSeeder.seedAll();
      final total = results.values.fold(0, (a, b) => a + b);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(total == 0
              ? 'All collections already seeded.'
              : 'Seeded $total total records across ${results.entries.where((e) => e.value > 0).length} collections.'),
          backgroundColor: total == 0 ? Colors.orange : Colors.green,
        ));
      }
    } catch (e) {
      _showError('Seed all failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
        await _loadCounts();
      }
    }
  }

  Future<void> _deleteAll() async {
    final total = _counts.values.fold(0, (a, b) => a + b);
    final confirmed = await _confirmDialog(
      'Delete ALL Mock Data',
      'This will permanently delete all $total mock documents across every collection. This cannot be undone.',
      destructive: true,
    );
    if (!confirmed) return;

    setState(() => _isWorking = true);
    try {
      final results = await MockDataSeeder.deleteAllMockData();
      final deleted = results.values.fold(0, (a, b) => a + b);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Deleted $deleted mock records total.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      _showError('Delete all failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
        await _loadCounts();
      }
    }
  }

  Future<bool> _confirmDialog(String title, String message,
      {bool destructive = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111C2F),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: Text(message,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              destructive ? 'DELETE ALL' : 'Confirm',
              style: TextStyle(
                  color: destructive ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final totalMock = _counts.values.fold(0, (a, b) => a + b);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadCounts,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              _headerCard(totalMock),
              const SizedBox(height: 16),

              // Global action buttons
              Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      label: 'Seed All',
                      icon: Icons.cloud_upload_outlined,
                      color: const Color(0xFF3B82F6),
                      onTap: _isWorking ? null : _seedAll,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionBtn(
                      label: 'Delete All',
                      icon: Icons.delete_sweep_outlined,
                      color: Colors.red,
                      onTap: _isWorking || totalMock == 0 ? null : _deleteAll,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'COLLECTIONS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ))
              else
                ..._collections.entries.map((entry) =>
                    _collectionCard(entry.key, entry.value)),
            ],
          ),
        ),
        if (_isWorking)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                color: Color(0xFF111C2F),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Working...',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _headerCard(int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2744), Color(0xFF0F1A30)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D4A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.data_object,
                color: Color(0xFF3B82F6), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mock Data Manager',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total total mock documents in Firestore',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _isWorking ? null : _loadCounts,
          ),
        ],
      ),
    );
  }

  Widget _collectionCard(String key, String label) {
    final count = _counts[key] ?? 0;
    final icon = _icons[key] ?? Icons.storage;

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
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: count > 0
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count docs',
                  style: TextStyle(
                    color: count > 0
                        ? const Color(0xFF10B981)
                        : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _smallBtn(
                  label: count > 0 ? 'Re-seed' : 'Seed',
                  icon: Icons.cloud_upload_outlined,
                  color: const Color(0xFF3B82F6),
                  onTap: _isWorking
                      ? null
                      : () => _seed(key, force: count > 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _smallBtn(
                  label: 'Delete',
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: _isWorking || count == 0
                      ? null
                      : () => _delete(key),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: color.withOpacity(onTap == null ? 0.05 : 0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: onTap == null ? Colors.white24 : color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    color: onTap == null ? Colors.white24 : color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallBtn({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: color.withOpacity(onTap == null ? 0.04 : 0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: onTap == null ? Colors.white24 : color, size: 15),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    color: onTap == null ? Colors.white24 : color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
