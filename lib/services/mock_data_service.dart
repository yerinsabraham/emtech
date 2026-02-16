import '../models/book_model.dart';
import '../models/course_model.dart';
import '../models/daily_task_model.dart';
import '../models/forum_post_model.dart';
import '../models/blog_post_model.dart';
import '../config/mock_data_config.dart';

/// Mock Data Service
/// Provides sample data for demonstration and UI testing purposes
class MockDataService {
  // ════════════════════════════════════════════
  // COURSES (Premium & Free)
  // ════════════════════════════════════════════
  
  static List<CourseModel> getMockCourses({String? category}) {
    if (!MockDataConfig.isEnabledFor('courses')) return [];
    
    final allCourses = [
      // Premium Courses
      CourseModel(
        id: 'mock_1',
        title: 'Advanced Web Development',
        description: 'Master React, Node.js, and MongoDB to build full-stack applications',
        instructor: 'Dr. Sarah Johnson',
        priceEmc: 150,
        category: 'Premium',
        thumbnailUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=400',
        modules: ['React Fundamentals', 'State Management', 'Backend APIs', 'Database Design'],
        duration: 60,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        studentsEnrolled: 234,
      ),
      CourseModel(
        id: 'mock_2',
        title: 'Mobile App Development with Flutter',
        description: 'Build beautiful cross-platform mobile applications',
        instructor: 'Prof. Michael Chen',
        priceEmc: 200,
        category: 'Premium',
        thumbnailUrl: 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=400',
        modules: ['Flutter Basics', 'Widgets', 'State Management', 'Firebase Integration'],
        duration: 80,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        studentsEnrolled: 189,
      ),
      CourseModel(
        id: 'mock_3',
        title: 'Data Science & Machine Learning',
        description: 'Learn Python, statistics, and ML algorithms',
        instructor: 'Dr. Emily Rodriguez',
        priceEmc: 250,
        category: 'Premium',
        thumbnailUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400',
        modules: ['Python Basics', 'Data Analysis', 'ML Algorithms', 'Deep Learning'],
        duration: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        studentsEnrolled: 312,
      ),
      CourseModel(
        id: 'mock_4',
        title: 'Cloud Computing & DevOps',
        description: 'Master AWS, Docker, Kubernetes, and CI/CD',
        instructor: 'Prof. David Kim',
        priceEmc: 180,
        category: 'Premium',
        thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400',
        modules: ['AWS Fundamentals', 'Docker', 'Kubernetes', 'CI/CD Pipelines'],
        duration: 70,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        studentsEnrolled: 156,
      ),
      CourseModel(
        id: 'mock_5',
        title: 'Blockchain & Smart Contracts',
        description: 'Build decentralized applications on Ethereum',
        instructor: 'Dr. Alex Thompson',
        priceEmc: 300,
        category: 'Premium',
        thumbnailUrl: 'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?w=400',
        modules: ['Blockchain Basics', 'Solidity', 'Smart Contracts', 'DApp Development'],
        duration: 90,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        studentsEnrolled: 98,
      ),
      
      // Freemium Courses
      CourseModel(
        id: 'mock_6',
        title: 'Introduction to Programming',
        description: 'Learn the fundamentals of programming with Python',
        instructor: 'Prof. Lisa Anderson',
        priceEmc: 0,
        category: 'Freemium',
        thumbnailUrl: 'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?w=400',
        modules: ['Variables', 'Functions', 'Loops', 'Data Structures'],
        duration: 30,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        studentsEnrolled: 567,
      ),
      CourseModel(
        id: 'mock_7',
        title: 'HTML & CSS Basics',
        description: 'Start your web development journey',
        instructor: 'James Wilson',
        priceEmc: 0,
        category: 'Freemium',
        thumbnailUrl: 'https://images.unsplash.com/photo-1507721999472-8ed4421c4af2?w=400',
        modules: ['HTML Elements', 'CSS Styling', 'Flexbox', 'Responsive Design'],
        duration: 25,
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        studentsEnrolled: 823,
      ),
      CourseModel(
        id: 'mock_8',
        title: 'Git & GitHub for Beginners',
        description: 'Version control essentials every developer needs',
        instructor: 'Rachel Green',
        priceEmc: 0,
        category: 'Freemium',
        thumbnailUrl: 'https://images.unsplash.com/photo-1556075798-4825dfaaf498?w=400',
        modules: ['Git Basics', 'Branching', 'Remote Repositories', 'Collaboration'],
        duration: 15,
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
        studentsEnrolled: 645,
      ),
      CourseModel(
        id: 'mock_9',
        title: 'Database Fundamentals',
        description: 'Understanding SQL and relational databases',
        instructor: 'Dr. Robert Brown',
        priceEmc: 0,
        category: 'Freemium',
        thumbnailUrl: 'https://images.unsplash.com/photo-1544383835-bda2bc66a55d?w=400',
        modules: ['SQL Basics', 'Table Design', 'Queries', 'Joins'],
        duration: 35,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        studentsEnrolled: 412,
      ),
      CourseModel(
        id: 'mock_10',
        title: 'UI/UX Design Principles',
        description: 'Create beautiful and user-friendly interfaces',
        instructor: 'Maria Garcia',
        priceEmc: 0,
        category: 'Freemium',
        thumbnailUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400',
        modules: ['Design Thinking', 'Color Theory', 'Typography', 'Prototyping'],
        duration: 40,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        studentsEnrolled: 531,
      ),
    ];
    
    if (category != null && category != 'All') {
      return allCourses.where((c) => c.category == category).toList();
    }
    return allCourses;
  }

  // ════════════════════════════════════════════
  // BOOKS
  // ════════════════════════════════════════════
  
  static List<BookModel> getMockBooks({String? category}) {
    if (!MockDataConfig.isEnabledFor('books')) return [];
    
    final allBooks = [
      // Textbooks
      BookModel(
        id: 'book_1',
        title: 'Introduction to Algorithms',
        author: 'Thomas H. Cormen',
        description: 'The comprehensive guide to understanding algorithms and data structures',
        priceEmc: 120,
        category: 'Textbooks',
        coverImageUrl: 'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      BookModel(
        id: 'book_2',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        description: 'A handbook of agile software craftsmanship',
        priceEmc: 95,
        category: 'Textbooks',
        coverImageUrl: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 55)),
      ),
      BookModel(
        id: 'book_3',
        title: 'Design Patterns',
        author: 'Erich Gamma',
        description: 'Elements of reusable object-oriented software',
        priceEmc: 110,
        category: 'Textbooks',
        coverImageUrl: 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
      ),
      BookModel(
        id: 'book_4',
        title: 'Database System Concepts',
        author: 'Abraham Silberschatz',
        description: 'Comprehensive database theory and implementation',
        priceEmc: 130,
        category: 'Textbooks',
        coverImageUrl: 'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      BookModel(
        id: 'book_5',
        title: 'Computer Networks',
        author: 'Andrew S. Tanenbaum',
        description: 'Understanding modern networking protocols and architectures',
        priceEmc: 105,
        category: 'Textbooks',
        coverImageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      ),
      
      // Novels
      BookModel(
        id: 'book_6',
        title: 'The Phoenix Project',
        author: 'Gene Kim',
        description: 'A novel about IT, DevOps, and helping your business win',
        priceEmc: 45,
        category: 'Novels',
        coverImageUrl: 'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
      ),
      BookModel(
        id: 'book_7',
        title: 'The Unicorn Project',
        author: 'Gene Kim',
        description: 'A novel about developers, digital disruption, and thriving',
        priceEmc: 50,
        category: 'Novels',
        coverImageUrl: 'https://images.unsplash.com/photo-1519682577862-22b62b24e493?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      BookModel(
        id: 'book_8',
        title: 'Ready Player One',
        author: 'Ernest Cline',
        description: 'A futuristic adventure in virtual reality',
        priceEmc: 40,
        category: 'Novels',
        coverImageUrl: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      BookModel(
        id: 'book_9',
        title: 'Neuromancer',
        author: 'William Gibson',
        description: 'The groundbreaking cyberpunk classic',
        priceEmc: 38,
        category: 'Novels',
        coverImageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      
      // Reference
      BookModel(
        id: 'book_10',
        title: 'Python Quick Reference',
        author: 'Mark Lutz',
        description: 'Complete Python language reference guide',
        priceEmc: 60,
        category: 'Reference',
        coverImageUrl: 'https://images.unsplash.com/photo-1589998059171-988d887df646?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      BookModel(
        id: 'book_11',
        title: 'JavaScript: The Definitive Guide',
        author: 'David Flanagan',
        description: 'Master the world\'s most-used programming language',
        priceEmc: 75,
        category: 'Reference',
        coverImageUrl: 'https://images.unsplash.com/photo-1516979187457-637abb4f9353?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      BookModel(
        id: 'book_12',
        title: 'SQL Pocket Guide',
        author: 'Alice Zhao',
        description: 'Quick reference for SQL syntax and commands',
        priceEmc: 35,
        category: 'Reference',
        coverImageUrl: 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      BookModel(
        id: 'book_13',
        title: 'Docker Reference Manual',
        author: 'Karl Matthias',
        description: 'Complete guide to containerization',
        priceEmc: 55,
        category: 'Reference',
        coverImageUrl: 'https://images.unsplash.com/photo-1550399105-c4db5fb85c18?w=300',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
    
    if (category != null && category != 'All Books') {
      return allBooks.where((b) => b.category == category).toList();
    }
    return allBooks;
  }

  // ════════════════════════════════════════════
  // DAILY TASKS
  // ════════════════════════════════════════════
  
  static List<DailyTaskModel> getMockDailyTasks() {
    if (!MockDataConfig.isEnabledFor('dailyTasks')) return [];
    
    final tomorrow = DateTime.now().add(const Duration(hours: 24));
    
    return [
      DailyTaskModel(
        id: 'task_1',
        title: 'Complete a lesson',
        description: 'Finish at least one lesson in any enrolled course',
        rewardEmc: 10,
        category: 'learning',
        expiresAt: tomorrow,
        iconName: 'school',
      ),
      DailyTaskModel(
        id: 'task_2',
        title: 'Submit an assignment',
        description: 'Turn in any pending assignment',
        rewardEmc: 25,
        category: 'learning',
        expiresAt: tomorrow,
        iconName: 'assignment_turned_in',
      ),
      DailyTaskModel(
        id: 'task_3',
        title: 'Join a live class',
        description: 'Attend at least one live class session',
        rewardEmc: 15,
        category: 'learning',
        expiresAt: tomorrow,
        iconName: 'video_call',
      ),
      DailyTaskModel(
        id: 'task_4',
        title: 'Post in the forum',
        description: 'Share your thoughts or ask a question in the student forum',
        rewardEmc: 8,
        category: 'social',
        expiresAt: tomorrow,
        iconName: 'forum',
      ),
      DailyTaskModel(
        id: 'task_5',
        title: 'Help a classmate',
        description: 'Reply to someone\'s question in the forum',
        rewardEmc: 12,
        category: 'social',
        expiresAt: tomorrow,
        iconName: 'people',
      ),
      DailyTaskModel(
        id: 'task_6',
        title: 'Read a blog post',
        description: 'Stay updated with the latest news and tutorials',
        rewardEmc: 5,
        category: 'achievement',
        expiresAt: tomorrow,
        iconName: 'article',
      ),
      DailyTaskModel(
        id: 'task_7',
        title: 'Study for 30 minutes',
        description: 'Spend at least 30 minutes on learning materials',
        rewardEmc: 20,
        category: 'learning',
        expiresAt: tomorrow,
        iconName: 'timer',
      ),
    ];
  }

  // ════════════════════════════════════════════
  // FORUM POSTS
  // ════════════════════════════════════════════
  
  static List<ForumPostModel> getMockForumPosts({String? category}) {
    if (!MockDataConfig.isEnabledFor('forum')) return [];
    
    final allPosts = [
      ForumPostModel(
        id: 'post_1',
        authorId: 'user_1',
        authorName: 'Alex Johnson',
        title: 'How to debug React hooks effectively?',
        content: 'I\'m having trouble understanding the lifecycle of useEffect. Can someone explain when it runs and how to properly clean up?',
        category: 'question',
        likes: 23,
        replies: 8,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        tags: ['react', 'javascript', 'hooks'],
        isPinned: false,
      ),
      ForumPostModel(
        id: 'post_2',
        authorId: 'admin_1',
        authorName: 'Dr. Sarah Johnson',
        title: 'Welcome to EMTech - Start Here!',
        content: 'Welcome all new students! Please introduce yourself and let us know what you\'re excited to learn.',
        category: 'announcement',
        likes: 156,
        replies: 42,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        tags: ['welcome', 'introduction'],
        isPinned: true,
      ),
      ForumPostModel(
        id: 'post_3',
        authorId: 'user_2',
        authorName: 'Maria Garcia',
        title: 'Best resources for learning Flutter?',
        content: 'I just started the Flutter course and want to supplement with additional resources. What do you recommend?',
        category: 'discussion',
        likes: 34,
        replies: 15,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        tags: ['flutter', 'resources', 'mobile'],
      ),
      ForumPostModel(
        id: 'post_4',
        authorId: 'user_3',
        authorName: 'David Kim',
        title: 'How do I optimize database queries?',
        content: 'My application is slowing down with large datasets. Looking for tips on query optimization.',
        category: 'question',
        likes: 18,
        replies: 6,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        tags: ['database', 'performance', 'sql'],
      ),
      ForumPostModel(
        id: 'post_5',
        authorId: 'user_4',
        authorName: 'Emily Rodriguez',
        title: 'Study Group for Data Science Course',
        content: 'Anyone interested in forming a study group for the Data Science course? We can meet weekly to discuss concepts.',
        category: 'discussion',
        likes: 45,
        replies: 22,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        tags: ['study-group', 'data-science', 'collaboration'],
      ),
      ForumPostModel(
        id: 'post_6',
        authorId: 'user_5',
        authorName: 'James Wilson',
        title: 'Tips for acing the final exam',
        content: 'Just finished the Web Development course with an A. Here are my top tips for success...',
        category: 'discussion',
        likes: 67,
        replies: 19,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        tags: ['tips', 'exams', 'web-development'],
      ),
    ];
    
    if (category != null) {
      return allPosts.where((p) => p.category == category).toList();
    }
    return allPosts;
  }

  // ════════════════════════════════════════════
  // BLOG POSTS
  // ════════════════════════════════════════════
  
  static List<BlogPostModel> getMockBlogPosts({String? category}) {
    if (!MockDataConfig.isEnabledFor('blog')) return [];
    
    final allPosts = [
      BlogPostModel(
        id: 'blog_1',
        title: 'Introducing EMTech 2.0: The Future of Learning',
        excerpt: 'We\'re excited to announce major updates to the EMTech platform, including new courses and enhanced features.',
        content: 'Full article content here...',
        author: 'EMTech Team',
        category: 'announcement',
        imageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800',
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        readTimeMinutes: 5,
        tags: ['platform', 'updates', 'features'],
      ),
      BlogPostModel(
        id: 'blog_2',
        title: '10 Tips for Effective Online Learning',
        excerpt: 'Master the art of online education with these proven strategies from successful students.',
        content: 'Full article content here...',
        author: 'Dr. Sarah Johnson',
        category: 'tutorial',
        imageUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800',
        publishedAt: DateTime.now().subtract(const Duration(days: 7)),
        readTimeMinutes: 8,
        tags: ['learning', 'tips', 'productivity'],
      ),
      BlogPostModel(
        id: 'blog_3',
        title: 'How Our Students Are Landing Tech Jobs',
        excerpt: 'Success stories from EMTech graduates who secured positions at top companies.',
        content: 'Full article content here...',
        author: 'Career Services',
        category: 'news',
        imageUrl: 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800',
        publishedAt: DateTime.now().subtract(const Duration(days: 10)),
        readTimeMinutes: 6,
        tags: ['career', 'success', 'jobs'],
      ),
      BlogPostModel(
        id: 'blog_4',
        title: 'Getting Started with Machine Learning',
        excerpt: 'A beginner\'s guide to understanding and applying machine learning concepts.',
        content: 'Full article content here...',
        author: 'Dr. Emily Rodriguez',
        category: 'tutorial',
        imageUrl: 'https://images.unsplash.com/photo-1555949963-aa79dcee981c?w=800',
        publishedAt: DateTime.now().subtract(const Duration(days: 14)),
        readTimeMinutes: 12,
        tags: ['machine-learning', 'ai', 'tutorial'],
      ),
      BlogPostModel(
        id: 'blog_5',
        title: 'New Blockchain Course Now Available',
        excerpt: 'Learn to build decentralized applications with our comprehensive blockchain development course.',
        content: 'Full article content here...',
        author: 'Dr. Alex Thompson',
        category: 'news',
        imageUrl: 'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?w=800',
        publishedAt: DateTime.now().subtract(const Duration(days: 5)),
        readTimeMinutes: 4,
        tags: ['blockchain', 'courses', 'web3'],
      ),
      BlogPostModel(
        id: 'blog_6',
        title: 'Building a Strong Developer Portfolio',
        excerpt: 'Essential projects and strategies to showcase your skills to potential employers.',
        content: 'Full article content here...',
        author: 'Michael Chen',
        category: 'tutorial',
        imageUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800',
        publishedAt: DateTime.now().subtract(const Duration(days: 12)),
        readTimeMinutes: 10,
        tags: ['portfolio', 'career', 'development'],
      ),
    ];
    
    if (category != null) {
      return allPosts.where((p) => p.category == category).toList();
    }
    return allPosts;
  }

  // ════════════════════════════════════════════
  // SCHOLARSHIP DATA
  // ════════════════════════════════════════════
  
  static List<Map<String, dynamic>> getMockScholarshipOpportunities() {
    if (!MockDataConfig.isEnabledFor('scholarships')) return [];
    
    return [
      {
        'id': 'scholarship_1',
        'title': 'Excellence in Technology Scholarship',
        'description': 'Full tuition coverage for top-performing students in technology courses',
        'amount': 100, // percentage
        'depositRequired': 30, // percentage
        'minimumGrade': 3.5,
        'deadline': DateTime.now().add(const Duration(days: 30)),
        'slots': 10,
        'applicants': 45,
      },
      {
        'id': 'scholarship_2',
        'title': 'Women in Tech Scholarship',
        'description': 'Supporting women pursuing careers in technology',
        'amount': 75,
        'depositRequired': 22.5,
        'minimumGrade': 3.0,
        'deadline': DateTime.now().add(const Duration(days: 45)),
        'slots': 15,
        'applicants': 32,
      },
      {
        'id': 'scholarship_3',
        'title': 'First Generation Student Award',
        'description': 'For students who are the first in their family to pursue higher education',
        'amount': 50,
        'depositRequired': 15,
        'minimumGrade': 2.5,
        'deadline': DateTime.now().add(const Duration(days: 60)),
        'slots': 20,
        'applicants': 67,
      },
      {
        'id': 'scholarship_4',
        'title': 'Community Impact Scholarship',
        'description': 'Awarded to students making a difference in their communities',
        'amount': 100,
        'depositRequired': 30,
        'minimumGrade': 3.0,
        'deadline': DateTime.now().add(const Duration(days: 25)),
        'slots': 5,
        'applicants': 28,
      },
    ];
  }

  // ════════════════════════════════════════════
  // STAKING DATA
  // ════════════════════════════════════════════
  
  static List<Map<String, dynamic>> getMockStakingData() {
    if (!MockDataConfig.isEnabledFor('staking')) return [];
    
    return [
      {
        'id': 'stake_1',
        'userId': 'mock_user',
        'userName': 'Demo Student',
        'stakedAmount': 5000.0,
        'tier': 'Silver',
        'apyPercentage': '10% APY',
        'durationDays': 30,
        'stakingDurationDays': 30,
        'isActive': true,
        'votingPower': 5.0,
        'createdAt': DateTime.now().subtract(const Duration(days: 15)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 15)),
      },
      {
        'id': 'stake_2',
        'userId': 'mock_user',
        'userName': 'Demo Student',
        'stakedAmount': 2500.0,
        'tier': 'Bronze',
        'apyPercentage': '5% APY',
        'durationDays': 60,
        'stakingDurationDays': 60,
        'isActive': true,
        'votingPower': 2.5,
        'createdAt': DateTime.now().subtract(const Duration(days: 45)),
        'updatedAt': DateTime.now().subtract(const Duration(days: 45)),
      },
    ];
  }

  // ════════════════════════════════════════════
  // REWARDS DATA
  // ════════════════════════════════════════════
  
  static List<Map<String, dynamic>> getMockRewardsData() {
    if (!MockDataConfig.isEnabledFor('rewards')) return [];
    
    return [
      {
        'id': 'reward_1',
        'userId': 'mock_user',
        'type': 'signup',
        'amount': 1000.0,
        'redeemed': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 90)),
        'redeemedAt': DateTime.now().subtract(const Duration(days: 90)),
        'courseType': null,
      },
      {
        'id': 'reward_2',
        'userId': 'mock_user',
        'courseId': 'mock_1',
        'type': 'enrollment',
        'amount': 2000.0,
        'redeemed': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 60)),
        'redeemedAt': DateTime.now().subtract(const Duration(days: 30)),
        'courseType': 'paid',
      },
      {
        'id': 'reward_3',
        'userId': 'mock_user',
        'courseId': 'mock_6',
        'type': 'enrollment',
        'amount': 1000.0,
        'redeemed': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 45)),
        'redeemedAt': DateTime.now().subtract(const Duration(days: 20)),
        'courseType': 'freemium',
      },
      {
        'id': 'reward_4',
        'userId': 'mock_user',
        'courseId': 'mock_1',
        'type': 'grade',
        'amount': 500.0,
        'redeemed': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
        'redeemedAt': DateTime.now().subtract(const Duration(days: 10)),
        'grade': 'A',
        'courseType': 'paid',
      },
      {
        'id': 'reward_5',
        'userId': 'mock_user',
        'type': 'daily_task',
        'amount': 25.0,
        'redeemed': false,
        'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
        'taskId': 'task_1',
      },
      {
        'id': 'reward_6',
        'userId': 'mock_user',
        'type': 'staking',
        'amount': 125.0,
        'redeemed': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'stakingId': 'stake_1',
      },
    ];
  }

  // ════════════════════════════════════════════
  // TRANSACTION HISTORY
  // ════════════════════════════════════════════
  
  static List<Map<String, dynamic>> getMockTransactions() {
    if (!MockDataConfig.isEnabledFor('transactions')) return [];
    
    return [
      {
        'id': 'txn_1',
        'userId': 'mock_user',
        'type': 'earn',
        'amount': 1000,
        'description': 'Welcome Bonus - Sign-up Reward',
        'relatedId': 'signup_reward',
        'createdAt': DateTime.now().subtract(const Duration(days: 90)),
      },
      {
        'id': 'txn_2',
        'userId': 'mock_user',
        'type': 'earn',
        'amount': 2000,
        'description': 'Course Completion Reward (Advanced Web Development)',
        'relatedId': 'mock_1',
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      },
      {
        'id': 'txn_3',
        'userId': 'mock_user',
        'type': 'earn',
        'amount': 500,
        'description': 'Grade A Achievement Bonus',
        'relatedId': 'mock_1',
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
      },
      {
        'id': 'txn_4',
        'userId': 'mock_user',
        'type': 'earn',
        'amount': 25,
        'description': 'Daily Task Completed: Complete a Quiz',
        'relatedId': 'task_1',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'id': 'txn_5',
        'userId': 'mock_user',
        'type': 'spend',
        'amount': 45,
        'description': 'Purchased: Introduction to Algorithms',
        'relatedId': 'book_1',
        'createdAt': DateTime.now().subtract(const Duration(days: 4)),
      },
      {
        'id': 'txn_6',
        'userId': 'mock_user',
        'type': 'earn',
        'amount': 20,
        'description': 'Daily Task Completed: Join Student Forum Discussion',
        'relatedId': 'task_2',
        'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        'id': 'txn_7',
        'userId': 'mock_user',
        'type': 'stake',
        'amount': 5000,
        'description': 'Staked 5,000 EMC (Silver Tier)',
        'relatedId': 'stake_1',
        'createdAt': DateTime.now().subtract(const Duration(days: 15)),
      },
      {
        'id': 'txn_8',
        'userId': 'mock_user',
        'type': 'earn',
        'amount': 15,
        'description': 'Daily Task Completed: Read a Blog Article',
        'relatedId': 'task_3',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': 'txn_9',
        'userId': 'mock_user',
        'type': 'spend',
        'amount': 30,
        'description': 'Purchased: Clean Code',
        'relatedId': 'book_2',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': 'txn_10',
        'userId': 'mock_user',
        'type': 'earn',
        'amount': 125,
        'description': 'Staking Rewards (15 days)',
        'relatedId': 'stake_1',
        'createdAt': DateTime.now().subtract(const Duration(hours: 12)),
      },
      {
        'id': 'txn_11',
        'userId': 'mock_user',
        'type': 'earn',
        'amount': 1000,
        'description': 'Course Completion Reward (Intro to Programming)',
        'relatedId': 'mock_6',
        'createdAt': DateTime.now().subtract(const Duration(days: 20)),
      },
      {
        'id': 'txn_12',
        'userId': 'mock_user',
        'type': 'spend',
        'amount': 200,
        'description': 'Enrolled in Mobile App Development',
        'relatedId': 'mock_2',
        'createdAt': DateTime.now().subtract(const Duration(days: 60)),
      },
    ];
  }
}
