import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/call_service.dart';
import 'pages/home_page.dart';
import 'pages/bookshop_page.dart';
import 'pages/wallet_page.dart';
import 'pages/profile_page.dart';
import 'services/push_notification_service.dart';
import 'screens/login_page.dart';
import 'screens/lecturer/lecturer_dashboard_page.dart';
import 'screens/wallet/enhanced_wallet_page.dart';
import 'screens/edit_profile_page.dart';
import 'screens/settings_page.dart';
import 'screens/support_page.dart';
import 'screens/learning_history_page.dart';
import 'screens/saved_courses_page.dart';
import 'screens/achievements_page.dart';
import 'screens/incoming_call_overlay.dart';
import 'config/agora_config.dart';
import 'config/home_design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM push notifications
  await PushNotificationService.initialize();

  // Initialize Agora configuration from Firebase Remote Config
  await AgoraConfig.initialize();

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
        ChangeNotifierProvider(create: (_) => CallService()),
      ],
      child: MaterialApp(
        title: 'Emtech School',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.surface,
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
    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      // Navigate to main app
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainShell(),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
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
    if (!authService.isAuthenticated || authService.userModel == null) {
      // Not logged in or user data not loaded yet - default student view
      return const [HomePage(), BookshopPage(), WalletPage(), ProfilePage()];
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
          icon: Icon(Iconsax.home),
          activeIcon: Icon(Iconsax.home_2),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.book),
          activeIcon: Icon(Iconsax.book_1),
          label: 'Bookshop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.wallet),
          activeIcon: Icon(Iconsax.wallet_2),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.user),
          activeIcon: Icon(Iconsax.user_edit),
          label: 'Profile',
        ),
      ];
    }

    if (authService.isLecturer) {
      // Lecturer navigation
      return const [
        BottomNavigationBarItem(
          icon: Icon(Iconsax.home),
          activeIcon: Icon(Iconsax.home_2),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.book_saved),
          activeIcon: Icon(Iconsax.book_saved),
          label: 'My Courses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.wallet),
          activeIcon: Icon(Iconsax.wallet_2),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.user),
          activeIcon: Icon(Iconsax.user_edit),
          label: 'Profile',
        ),
      ];
    } else {
      // Student navigation (default)
      return const [
        BottomNavigationBarItem(
          icon: Icon(Iconsax.home),
          activeIcon: Icon(Iconsax.home_2),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.book),
          activeIcon: Icon(Iconsax.book_1),
          label: 'Bookshop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.wallet),
          activeIcon: Icon(Iconsax.wallet_2),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Iconsax.user),
          activeIcon: Icon(Iconsax.user_edit),
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
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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

    return IncomingCallListener(
      child: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.stroke.withValues(alpha: 0.8),
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowPrimary,
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SalomonBottomBar(
              currentIndex: _currentIndex,
              onTap: (i) {
                final requiresAuth = [2, 3];

                if (requiresAuth.contains(i) && !authService.isAuthenticated) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.9,
                      decoration: const BoxDecoration(
                        color: Color(0xFF080C14),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: const LoginPage(),
                    ),
                  );
                } else {
                  setState(() => _currentIndex = i);
                }
              },
              items: navItems
                  .map(
                    (item) => SalomonBottomBarItem(
                      icon: item.icon,
                      title: Text(item.label ?? ''),
                      selectedColor: AppColors.primary,
                      unselectedColor: AppColors.textMuted,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
