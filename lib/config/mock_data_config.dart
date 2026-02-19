/// Mock Data Configuration
/// 
/// Toggle this to enable/disable mock data throughout the app.
/// When enabled, the app will use sample data for demonstration purposes.
/// When disabled, the app will use live Firebase data.
class MockDataConfig {
  /// Set this to `true` to use mock data, `false` to use live Firebase data
  static const bool useMockData = true;
  
  /// Enable specific mock data categories
  static const bool mockCourses = false;
  static const bool mockBooks = true;
  static const bool mockDailyTasks = true;
  static const bool mockScholarships = true;
  static const bool mockForum = true;
  static const bool mockBlog = true;
  static const bool mockStaking = true;
  static const bool mockRewards = true;
  static const bool mockTransactions = true;
  
  /// Helper method to check if mock data should be used
  static bool get isEnabled => useMockData;
  
  /// Helper method to check specific category
  static bool isEnabledFor(String category) {
    if (!useMockData) return false;
    
    switch (category) {
      case 'courses':
        return mockCourses;
      case 'books':
        return mockBooks;
      case 'dailyTasks':
        return mockDailyTasks;
      case 'scholarships':
        return mockScholarships;
      case 'forum':
        return mockForum;
      case 'blog':
        return mockBlog;
      case 'staking':
        return mockStaking;
      case 'rewards':
        return mockRewards;
      case 'transactions':
        return mockTransactions;
      default:
        return false;
    }
  }
}
