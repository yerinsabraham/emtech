import 'package:cloud_firestore/cloud_firestore.dart';
import 'mock_data_service.dart';

/// Seeds mock data into Firestore with `isMockData: true` flag.
/// Admins can then view and delete this data from the Mock Data Management tab.
class MockDataSeeder {
  static final _db = FirebaseFirestore.instance;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns how many mock documents currently exist per collection.
  static Future<Map<String, int>> getMockCounts() async {
    final collections = ['courses', 'books', 'dailyTasks', 'forumPosts', 'blogPosts'];
    final Map<String, int> counts = {};
    await Future.wait(collections.map((col) async {
      final snap = await _db
          .collection(col)
          .where('isMockData', isEqualTo: true)
          .count()
          .get();
      counts[col] = snap.count ?? 0;
    }));
    return counts;
  }

  /// Returns true if a collection already has mock data seeded.
  static Future<bool> isMockSeeded(String collection) async {
    final snap = await _db
        .collection(collection)
        .where('isMockData', isEqualTo: true)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Seed helpers ────────────────────────────────────────────────────────────

  static Future<int> seedCourses({bool force = false}) => _seed(
        collection: 'courses',
        force: force,
        getData: () => MockDataService.getMockCourses()
            .map((c) => c.toMap()..['isMockData'] = true)
            .toList(),
      );

  static Future<int> seedBooks({bool force = false}) => _seed(
        collection: 'books',
        force: force,
        getData: () => MockDataService.getMockBooks()
            .map((b) => b.toMap()..['isMockData'] = true)
            .toList(),
      );

  static Future<int> seedDailyTasks({bool force = false}) => _seed(
        collection: 'dailyTasks',
        force: force,
        getData: () => MockDataService.getMockDailyTasks()
            .map((t) => t.toMap()..['isMockData'] = true)
            .toList(),
      );

  static Future<int> seedForumPosts({bool force = false}) => _seed(
        collection: 'forumPosts',
        force: force,
        getData: () => MockDataService.getMockForumPosts()
            .map((p) => p.toMap()..['isMockData'] = true)
            .toList(),
      );

  static Future<int> seedBlogPosts({bool force = false}) => _seed(
        collection: 'blogPosts',
        force: force,
        getData: () => MockDataService.getMockBlogPosts()
            .map((p) => p.toMap()..['isMockData'] = true)
            .toList(),
      );

  /// Seeds all categories at once. Skips categories that are already seeded
  /// unless [force] is true.
  static Future<Map<String, int>> seedAll({bool force = false}) async {
    final results = await Future.wait([
      seedCourses(force: force),
      seedBooks(force: force),
      seedDailyTasks(force: force),
      seedForumPosts(force: force),
      seedBlogPosts(force: force),
    ]);
    return {
      'courses': results[0],
      'books': results[1],
      'dailyTasks': results[2],
      'forumPosts': results[3],
      'blogPosts': results[4],
    };
  }

  // ── Delete helpers ──────────────────────────────────────────────────────────

  static Future<int> deleteMockData(String collection) async {
    final snap = await _db
        .collection(collection)
        .where('isMockData', isEqualTo: true)
        .get();

    if (snap.docs.isEmpty) return 0;

    final batches = <WriteBatch>[];
    WriteBatch batch = _db.batch();
    int opCount = 0;

    for (final doc in snap.docs) {
      batch.delete(doc.reference);
      opCount++;
      if (opCount == 500) {
        batches.add(batch);
        batch = _db.batch();
        opCount = 0;
      }
    }
    if (opCount > 0) batches.add(batch);

    await Future.wait(batches.map((b) => b.commit()));
    return snap.docs.length;
  }

  static Future<Map<String, int>> deleteAllMockData() async {
    final collections = ['courses', 'books', 'dailyTasks', 'forumPosts', 'blogPosts'];
    final Map<String, int> deleted = {};
    await Future.wait(collections.map((col) async {
      deleted[col] = await deleteMockData(col);
    }));
    return deleted;
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  /// Generic seed helper. Writes items using batched writes (max 500/batch).
  static Future<int> _seed({
    required String collection,
    required bool force,
    required List<Map<String, dynamic>> Function() getData,
  }) async {
    if (!force && await isMockSeeded(collection)) return 0;

    final items = getData();
    if (items.isEmpty) return 0;

    final batches = <WriteBatch>[];
    WriteBatch batch = _db.batch();
    int opCount = 0;

    for (final item in items) {
      final ref = _db.collection(collection).doc();
      batch.set(ref, item);
      opCount++;
      if (opCount == 500) {
        batches.add(batch);
        batch = _db.batch();
        opCount = 0;
      }
    }
    if (opCount > 0) batches.add(batch);

    await Future.wait(batches.map((b) => b.commit()));
    return items.length;
  }
}
