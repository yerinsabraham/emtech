import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'screens/login_page.dart';
import 'screens/admin/admin_panel_page.dart';
import 'screens/lecturer/lecturer_dashboard_page.dart';
import 'screens/notifications_page.dart';
import 'screens/wallet/enhanced_wallet_page.dart';
import 'screens/student/loan_application_page.dart';
import 'screens/edit_profile_page.dart';
import 'screens/settings_page.dart';
import 'screens/support_page.dart';
import 'screens/learning_history_page.dart';
import 'screens/saved_courses_page.dart';
import 'screens/achievements_page.dart';
import 'screens/courses_list_page.dart';
import 'screens/about_info_desk_page.dart';
import 'screens/blog_news_page.dart';
import 'screens/daily_tasks_page.dart';
import 'screens/scholarship_board_page.dart';
import 'screens/student_forum_page.dart';
import 'models/book_model.dart';
import 'models/transaction_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'Emtech School',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF080C14),
          primaryColor: Colors.white,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Color(0xFFBBBBBB),
            surface: Color(0xFF0F1A2E),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/edit-profile': (context) => const EditProfilePage(),
          '/settings': (context) => const SettingsPage(),
          '/support': (context) => const SupportPage(),
          '/learning-history': (context) => const LearningHistoryPage(),
          '/saved-courses': (context) => const SavedCoursesPage(),
          '/achievements': (context) => const AchievementsPage(),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      
      // Navigate to main app
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Programmatic recreation of the EMTECH SCHOOL logo
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'EMTECH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(4),
                        topRight: const Radius.circular(12),
                        bottomRight: const Radius.circular(12),
                        bottomLeft: const Radius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'SCHOOL',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN SHELL (Bottom Nav)
// ─────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> _getPagesForRole(AuthService authService) {
    if (!authService.isAuthenticated) {
      // Not logged in - default student view
      return const [
        HomePage(),
        BookshopPage(),
        _GuestWalletPage(),
        ProfilePage(),
      ];
    }

    if (authService.isLecturer) {
      // Lecturer view
      return [
        const HomePage(),
        const LecturerDashboardPage(),
        EnhancedWalletPage(userModel: authService.userModel!),
        const ProfilePage(),
      ];
    } else {
      // Student and Admin view (both use same nav: Home, Bookshop, Wallet, Profile)
      return [
        const HomePage(),
        const BookshopPage(),
        EnhancedWalletPage(userModel: authService.userModel!),
        const ProfilePage(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItemsForRole(AuthService authService) {
    if (!authService.isAuthenticated) {
      // Not logged in - default view
      return const [
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.home_outlined),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.home_rounded),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.menu_book_outlined),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.menu_book_rounded),
          ),
          label: 'Bookshop',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.account_balance_wallet_outlined),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.account_balance_wallet_rounded),
          ),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.person_outline_rounded),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.person_rounded),
          ),
          label: 'Profile',
        ),
      ];
    }

    if (authService.isLecturer) {
      // Lecturer navigation
      return const [
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.home_outlined),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.home_rounded),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.school_outlined),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.school),
          ),
          label: 'My Courses',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.account_balance_wallet_outlined),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.account_balance_wallet_rounded),
          ),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.person_outline_rounded),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.person_rounded),
          ),
          label: 'Profile',
        ),
      ];
    } else {
      // Student navigation (default)
      return const [
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.home_outlined),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.home_rounded),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.menu_book_outlined),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.menu_book_rounded),
          ),
          label: 'Bookshop',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.account_balance_wallet_outlined),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.account_balance_wallet_rounded),
          ),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.person_outline_rounded),
          ),
          activeIcon: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: Icon(Icons.person_rounded),
          ),
          label: 'Profile',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    // Show loading screen while user data is being loaded
    if (authService.isAuthenticated && authService.isLoadingUserData) {
      return const Scaffold(
        backgroundColor: Color(0xFF080C14),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }
    
    final pages = _getPagesForRole(authService);
    final navItems = _getNavItemsForRole(authService);

    // Reset index if it exceeds available pages
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }
    
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B1120),
          border: Border(
            top: BorderSide(color: Color(0xFF1A2940), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            // Check if the page requires authentication
            final requiresAuth = [2, 3]; // Wallet (2) and Profile (3) require auth
            
            if (requiresAuth.contains(i) && !authService.isAuthenticated) {
              // Show login modal
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF080C14),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const LoginPage(),
                ),
              );
            } else {
              setState(() => _currentIndex = i);
            }
          },
          backgroundColor: const Color(0xFF0B1120),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white30,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          iconSize: 24,
          elevation: 0,
          items: navItems,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HOME PAGE
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedSession = 'Summer';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),

              // ── Top Bar ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo text
                  Row(
                    children: [
                      const Text(
                        'EMTECH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(3),
                            topRight: const Radius.circular(8),
                            bottomRight: const Radius.circular(8),
                            bottomLeft: const Radius.circular(3),
                          ),
                        ),
                        child: const Text(
                          'SCHOOL',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Notification Bell
                  _buildNotificationBell(context),
                ],
              ),

              const SizedBox(height: 24),

              // ── Welcome Hero Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A2744), Color(0xFF0F1B30)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2A3F5F).withAlpha(80), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome To',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Emtech School',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CoursesListPage(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enroll for Diploma Course',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Sessions ──
              const Text(
                'Sessions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildSessionChip('Summer'),
                  _buildSessionChip('Winter'),
                  _buildSessionChip('Spring'),
                  _buildSessionChip('Harmatan'),
                ],
              ),

              const SizedBox(height: 26),

              // ── Feature Cards ──
              // Row 1: Freemium Courses + About/Info Desk
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      'Freemium\nCourses',
                      Icons.school_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFeatureCard(
                      'About /\nInfo Desk',
                      Icons.info_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Blog/News + more
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      'Blog /\nNews',
                      Icons.article_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFeatureCard(
                      'Support',
                      Icons.support_agent_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ── Three Horizontal Buttons ──
              // Daily Tasks, Scholarship Board, Student Forum
              Row(
                children: [
                  Expanded(
                    child: _buildCompactButton(
                      'Daily\nTask',
                      Icons.task_alt_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactButton(
                      'Scholarship\nBoard',
                      Icons.emoji_events_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactButton(
                      'Student\nForum',
                      Icons.forum_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionChip(String label) {
    final isSelected = _selectedSession == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSession = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF121D31),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF1E2D4A),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Widget? page;
            switch (title) {
              case 'Freemium\nCourses':
                page = const CoursesListPage();
                break;
              case 'About /\nInfo Desk':
                page = const AboutInfoDeskPage();
                break;
              case 'Blog /\nNews':
                page = const BlogNewsPage();
                break;
              case 'Support':
                page = const SupportPage();
                break;
            }
            if (page != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => page!),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: Colors.white60,
                  size: 28,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactButton(String title, IconData icon) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A2940), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Widget? page;
            switch (title) {
              case 'Daily\nTask':
                page = const DailyTasksPage();
                break;
              case 'Scholarship\nBoard':
                page = const ScholarshipBoardPage();
                break;
              case 'Student\nForum':
                page = const StudentForumPage();
                break;
            }
            if (page != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => page!),
              );
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white54,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    final authService = context.watch<AuthService>();
    final notificationService = context.watch<NotificationService>();
    
    // Start listening to notifications if user is logged in
    if (authService.isAuthenticated && authService.userModel != null) {
      notificationService.getNotificationsStream(authService.userModel!.uid);
    }

    return GestureDetector(
      onTap: () {
        if (authService.isAuthenticated) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NotificationsPage()),
          );
        } else {
          // Show login modal
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Color(0xFF080C14),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const LoginPage(),
            ),
          );
        }
      },
      child: Stack(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white70,
            size: 28,
          ),
          if (authService.isAuthenticated && notificationService.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  notificationService.unreadCount > 9 
                      ? '9+' 
                      : '${notificationService.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOOKSHOP PAGE
// ─────────────────────────────────────────────
class BookshopPage extends StatefulWidget {
  const BookshopPage({super.key});

  @override
  State<BookshopPage> createState() => _BookshopPageState();
}

class _BookshopPageState extends State<BookshopPage> {
  String _selectedCategory = 'All Books';

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<FirestoreService>();
    
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                const Text(
                  'Bookshop',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.search, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Categories
          Container(
            height: 45,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                _buildCategoryChip('All Books'),
                _buildCategoryChip('Textbooks'),
                _buildCategoryChip('Novels'),
                _buildCategoryChip('Reference'),
              ],
            ),
          ),

          // Book Grid
          Expanded(
            child: StreamBuilder(
              stream: firestoreService.getBooks(
                category: _selectedCategory == 'All Books' ? null : _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No books available',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                
                final books = snapshot.data!;
                
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return _buildBookCard(book);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = label),
        child: Chip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          backgroundColor: isSelected ? Colors.white : const Color(0xFF121D31),
          side: BorderSide(
            color: isSelected ? Colors.white : const Color(0xFF1E2D4A),
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(BookModel book) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final authService = context.read<AuthService>();
            
            // Check if user is authenticated
            if (!authService.isAuthenticated) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: const BoxDecoration(
                    color: Color(0xFF080C14),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const LoginPage(),
                ),
              );
              return;
            }
            
            final success = await authService.spendEmcTokens(
              book.priceEmc,
              'Purchased: ${book.title}',
            );
            
            if (!context.mounted) return;
            
            if (success) {
              final firestoreService = context.read<FirestoreService>();
              await firestoreService.addTransaction(
                TransactionModel(
                  id: '',
                  userId: authService.user!.uid,
                  type: 'spend',
                  amount: book.priceEmc,
                  description: 'Purchased: ${book.title}',
                  relatedId: book.id,
                  createdAt: DateTime.now(),
                ),
              );
              
              if (!context.mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Book purchased successfully!'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Insufficient EMC tokens'),
                  backgroundColor: Color(0xFFFF5252),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A2744),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white24,
                    size: 48,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${book.priceEmc} EMC',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white54,
                          size: 18,
                        ),
                      ],
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

// ─────────────────────────────────────────────
// EMC WALLET PAGE
// ─────────────────────────────────────────────
// Guest wallet page for non-authenticated users
class _GuestWalletPage extends StatelessWidget {
  const _GuestWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = context.watch<FirestoreService>();
    final userModel = authService.userModel;
    final emcBalance = userModel?.emcBalance ?? 0;
    final userId = authService.currentUser?.uid;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EMC Token Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A2744), Color(0xFF0F1B30)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2A3F5F).withAlpha(80),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          emcBalance.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'EMC',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Navigate to earning opportunities
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Complete daily tasks to earn EMC!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Earn'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Navigate to Bookshop
                              DefaultTabController.of(context).animateTo(1);
                            },
                            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                            label: const Text('Spend'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Transaction History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stream transactions from Firebase
              if (userId != null)
                StreamBuilder<List<TransactionModel>>(
                  stream: firestoreService.getTransactions(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Error loading transactions: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                      );
                    }

                    final transactions = snapshot.data ?? [];

                    if (transactions.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.white.withAlpha(26),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No transactions yet',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Start purchasing books or earning tokens!',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: transactions.map((transaction) {
                        final isEarned = transaction.type == 'earn';
                        IconData icon;

                        if (transaction.description.contains('Purchase')) {
                          icon = Icons.shopping_bag_outlined;
                        } else if (transaction.description.contains('Task')) {
                          icon = Icons.task_alt;
                        } else if (transaction.description.contains('Reward') ||
                            transaction.description.contains('Signup')) {
                          icon = Icons.card_giftcard;
                        } else if (transaction.description.contains('Quiz')) {
                          icon = Icons.quiz_outlined;
                        } else {
                          icon = isEarned ? Icons.add_circle_outline : Icons.remove_circle_outline;
                        }

                        return _buildTransactionTile(
                          transaction.description,
                          '${isEarned ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} EMC',
                          icon,
                          isEarned,
                          transaction.createdAt,
                        );
                      }).toList(),
                    );
                  },
                )
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Please log in to view transactions',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
      String title, String amount, IconData icon, bool isEarned, DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0E1827),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white54,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isEarned ? const Color(0xFF4CAF50) : const Color(0xFFFF5252),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// ─────────────────────────────────────────────
// PROFILE PAGE
// ─────────────────────────────────────────────
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userModel = authService.userModel;
    final currentUser = authService.currentUser;

    final displayName = userModel?.name ?? currentUser?.displayName ?? 'Emtech Student';
    final email = currentUser?.email ?? 'student@emtech.edu';
    final emcBalance = userModel?.emcBalance ?? 0;
    final enrolledCoursesCount = userModel?.enrolledCourses.length ?? 0;
    final session = userModel?.session ?? 'Not enrolled';

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2744),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2A3F5F).withAlpha(80),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white54,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              
              // Role Badge
              _buildRoleBadge(userModel?.role ?? 'student'),
              
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2744),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2A3F5F).withAlpha(80),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Session: $session',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      emcBalance.toStringAsFixed(0),
                      'EMC Tokens',
                      Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      enrolledCoursesCount.toString(),
                      'Courses',
                      Icons.school_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Admin Dashboard (only for admins)
              if (authService.isAdmin)
                _buildMenuItem(
                  context,
                  Icons.admin_panel_settings,
                  'Admin Dashboard',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminPanelPage(),
                      ),
                    );
                  },
                ),

              // Menu Items
              _buildMenuItem(
                context,
                Icons.person_outline,
                'Edit Profile',
                () {
                  Navigator.pushNamed(context, '/edit-profile');
                },
              ),
              _buildMenuItem(
                context,
                Icons.history,
                'Learning History',
                () {
                  Navigator.pushNamed(context, '/learning-history');
                },
              ),
              _buildMenuItem(
                context,
                Icons.bookmark_outline,
                'Saved Courses',
                () {
                  Navigator.pushNamed(context, '/saved-courses');
                },
              ),
              _buildMenuItem(
                context,
                Icons.emoji_events_outlined,
                'Achievements',
                () {
                  Navigator.pushNamed(context, '/achievements');
                },
              ),
              _buildMenuItem(
                context,
                Icons.settings_outlined,
                'Settings',
                () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              _buildMenuItem(
                context,
                Icons.help_outline,
                'Help & Support',
                () {
                  Navigator.pushNamed(context, '/support');
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                context,
                Icons.logout,
                'Logout',
                () async {
                  // Show confirmation dialog
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF111C2F),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Color(0xFFFF5252)),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true && context.mounted) {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  }
                },
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color badgeColor;
    IconData icon;
    String roleText;

    switch (role) {
      case 'admin':
        badgeColor = const Color(0xFFFF5252);
        icon = Icons.admin_panel_settings;
        roleText = 'ADMIN';
        break;
      case 'lecturer':
        badgeColor = const Color(0xFF448AFF);
        icon = Icons.school;
        roleText = 'LECTURER';
        break;
      default:
        badgeColor = const Color(0xFF66BB6A);
        icon = Icons.person;
        roleText = 'STUDENT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            roleText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white54,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? const Color(0xFFFF5252) : Colors.white54,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? const Color(0xFFFF5252) : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDestructive ? const Color(0xFFFF5252) : Colors.white24,
        ),
        onTap: onTap,
      ),
    );
  }
}
