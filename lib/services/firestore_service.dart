import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/transaction_model.dart';
import '../models/course_model.dart';
import '../config/mock_data_config.dart';
import 'mock_data_service.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ────────────────────────────────────────────
  // BOOKS
  // ────────────────────────────────────────────
  
  Stream<List<BookModel>> getBooks({String? category}) {
    // Use mock data if enabled
    if (MockDataConfig.isEnabledFor('books')) {
      return Stream.value(MockDataService.getMockBooks(category: category));
    }
    
    Query query = _firestore.collection('books');
    
    if (category != null && category != 'All Books') {
      query = query.where('category', isEqualTo: category);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<void> addBook(BookModel book) async {
    try {
      await _firestore.collection('books').add(book.toMap());
    } catch (e) {
      debugPrint('Error adding book: $e');
    }
  }

  // ────────────────────────────────────────────
  // TRANSACTIONS
  // ────────────────────────────────────────────
  
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _firestore.collection('transactions').add(transaction.toMap());
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  // ────────────────────────────────────────────
  // COURSES
  // ────────────────────────────────────────────
  
  Stream<List<CourseModel>> getCourses({String? category}) {
    // Use mock data if enabled
    if (MockDataConfig.isEnabledFor('courses')) {
      return Stream.value(MockDataService.getMockCourses(category: category));
    }
    
    Query query = _firestore.collection('courses');
    
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CourseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<void> addCourse(CourseModel course) async {
    try {
      await _firestore.collection('courses').add(course.toMap());
    } catch (e) {
      debugPrint('Error adding course: $e');
    }
  }

  Future<void> enrollInCourse(String userId, String courseId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'enrolledCourses': FieldValue.arrayUnion([courseId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error enrolling in course: $e');
    }
  }

  // ────────────────────────────────────────────
  // SEED DATA (for testing)
  // ────────────────────────────────────────────
  
  Future<void> seedSampleData() async {
    try {
      // Check if books already exist
      final booksSnapshot = await _firestore.collection('books').limit(1).get();
      if (booksSnapshot.docs.isNotEmpty) {
        debugPrint('Sample data already exists');
        return;
      }

      // Add sample books
      final sampleBooks = [
        BookModel(
          id: '',
          title: 'Programming Basics 1',
          author: 'John Doe',
          description: 'Learn the fundamentals of programming',
          priceEmc: 50,
          category: 'Textbooks',
          createdAt: DateTime.now(),
        ),
        BookModel(
          id: '',
          title: 'Advanced Algorithms',
          author: 'Jane Smith',
          description: 'Master complex algorithms and data structures',
          priceEmc: 100,
          category: 'Textbooks',
          createdAt: DateTime.now(),
        ),
        BookModel(
          id: '',
          title: 'The Great Novel',
          author: 'Alice Johnson',
          description: 'A captivating story',
          priceEmc: 30,
          category: 'Novels',
          createdAt: DateTime.now(),
        ),
        BookModel(
          id: '',
          title: 'Python Reference Guide',
          author: 'Bob Wilson',
          description: 'Complete Python reference',
          priceEmc: 75,
          category: 'Reference',
          createdAt: DateTime.now(),
        ),
      ];

      for (var book in sampleBooks) {
        await addBook(book);
      }

      // Add sample courses
      final sampleCourses = [
        CourseModel(
          id: '',
          title: 'Introduction to Web Development',
          description: 'Learn HTML, CSS, and JavaScript',
          instructor: 'Prof. Smith',
          priceEmc: 0, // Freemium
          category: 'Freemium',
          duration: 40,
          modules: ['HTML Basics', 'CSS Styling', 'JavaScript Fundamentals'],
          createdAt: DateTime.now(),
        ),
        CourseModel(
          id: '',
          title: 'Diploma in Software Engineering',
          description: 'Comprehensive software engineering program',
          instructor: 'Dr. Johnson',
          priceEmc: 500,
          category: 'Diploma',
          duration: 200,
          modules: ['Programming', 'Databases', 'Web Development', 'Mobile Apps'],
          createdAt: DateTime.now(),
        ),
      ];

      for (var course in sampleCourses) {
        await addCourse(course);
      }

      debugPrint('Sample data seeded successfully');
    } catch (e) {
      debugPrint('Error seeding sample data: $e');
    }
  }
}
