import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../config/home_design_tokens.dart';
import '../models/course_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/about_info_desk_page.dart';
import '../screens/blog_news_page.dart';
import '../screens/courses_list_page.dart';
import '../screens/daily_tasks_page.dart';
import '../screens/notifications_page.dart';
import '../screens/student/course_detail_page.dart';
import '../screens/support_page.dart';
import 'home_widgets/continue_learning_carousel.dart';
import 'home_widgets/home_header.dart';
import 'home_widgets/progress_chart_section.dart';
import 'home_widgets/quick_action_grid.dart';
import 'home_widgets/session_selector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String _selectedSession = 'Summer';
  int _carouselIndex = 0;
  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = context.watch<FirestoreService>();
    final userModel = authService.userModel;
    final displayName =
        userModel?.name ?? authService.currentUser?.displayName ?? 'Guest';

    return Scaffold(
      backgroundColor: HomeColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child:
                  HomeHeader(
                        displayName: displayName,
                        photoUrl: userModel?.photoUrl,
                        onSearchTap: _goToCourses,
                        onNotificationTap: _goToNotifications,
                        stats: [
                          const HomeHeaderStat(value: '25+', label: 'Lecture'),
                          HomeHeaderStat(
                            value: '${userModel?.enrolledCourses.length ?? 0}',
                            label: 'Enrolled',
                          ),
                          const HomeHeaderStat(value: '4.8', label: 'Rating'),
                        ],
                        notificationCount: 3,
                      )
                      .animate(controller: _entryCtrl)
                      .fadeIn(duration: 400.ms)
                      .slideY(
                        begin: -0.08,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
            ),
            SliverToBoxAdapter(
              child:
                  _buildContinueLearningCarousel(authService, firestoreService)
                      .animate(controller: _entryCtrl)
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(
                        begin: 0.14,
                        delay: 100.ms,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: HomeSpacing.s20)),
            SliverToBoxAdapter(
              child:
                  SessionSelector(
                        sessions: const [
                          'Summer',
                          'Winter',
                          'Spring',
                          'Harmatan',
                        ],
                        selectedSession: _selectedSession,
                        onSessionChanged: (session) {
                          setState(() => _selectedSession = session);
                        },
                      )
                      .animate(controller: _entryCtrl)
                      .fadeIn(delay: 200.ms, duration: 350.ms)
                      .slideY(
                        begin: 0.12,
                        delay: 200.ms,
                        duration: 350.ms,
                        curve: Curves.easeOut,
                      ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: HomeSpacing.s20)),
            SliverToBoxAdapter(
              child: _buildProgressChartSection(authService, firestoreService)
                  .animate(controller: _entryCtrl)
                  .fadeIn(delay: 300.ms, duration: 350.ms)
                  .slideY(
                    begin: 0.12,
                    delay: 300.ms,
                    duration: 350.ms,
                    curve: Curves.easeOut,
                  ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: HomeSpacing.s20)),
            SliverToBoxAdapter(
              child:
                  QuickActionGrid(
                        items: [
                          HomeQuickActionItem(
                            label: 'Info Desk',
                            icon: Iconsax.info_circle,
                            accentColor: AppColors.primary,
                            onTap: _goToInfoDesk,
                          ),
                          HomeQuickActionItem(
                            label: 'News',
                            icon: Iconsax.document_text,
                            accentColor: AppColors.accent,
                            onTap: _goToNews,
                          ),
                          HomeQuickActionItem(
                            label: 'Support',
                            icon: Iconsax.message_question,
                            accentColor: AppColors.teal,
                            onTap: _goToSupport,
                          ),
                          HomeQuickActionItem(
                            label: 'Tasks',
                            icon: Iconsax.task_square,
                            accentColor: AppColors.accent,
                            onTap: _goToTasks,
                          ),
                        ],
                      )
                      .animate(controller: _entryCtrl)
                      .fadeIn(delay: 400.ms, duration: 300.ms)
                      .slideY(
                        begin: 0.1,
                        delay: 400.ms,
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: HomeSpacing.s32)),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearningCarousel(
    AuthService authService,
    FirestoreService firestoreService,
  ) {
    final userModel = authService.userModel;

    return StreamBuilder<List<CourseModel>>(
      stream: firestoreService.getCourses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ContinueLearningCarousel(
            courses: const [],
            activeIndex: _carouselIndex,
            onPageChanged: (index) => setState(() => _carouselIndex = index),
            onCourseTap: _goToCourse,
            onBrowseTap: _goToCourses,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return ContinueLearningCarousel(
            courses: const [],
            activeIndex: _carouselIndex,
            onPageChanged: (index) => setState(() => _carouselIndex = index),
            onCourseTap: _goToCourse,
            onBrowseTap: _goToCourses,
            isLoading: true,
          );
        }

        final allCourses = snapshot.data ?? const <CourseModel>[];
        final enrolledCourses = (userModel == null)
            ? const <CourseModel>[]
            : allCourses
                  .where(
                    (course) => userModel.enrolledCourses.contains(course.id),
                  )
                  .toList();

        return ContinueLearningCarousel(
          courses: enrolledCourses,
          activeIndex: _carouselIndex,
          onPageChanged: (index) => setState(() => _carouselIndex = index),
          onCourseTap: _goToCourse,
          onBrowseTap: _goToCourses,
        );
      },
    );
  }

  Widget _buildProgressChartSection(
    AuthService authService,
    FirestoreService firestoreService,
  ) {
    final userModel = authService.userModel;

    return StreamBuilder<List<CourseModel>>(
      stream: firestoreService.getCourses(),
      builder: (context, snapshot) {
        final allCourses = snapshot.data ?? const <CourseModel>[];
        final enrolledCourses = (userModel == null)
            ? const <CourseModel>[]
            : allCourses
                  .where(
                    (course) => userModel.enrolledCourses.contains(course.id),
                  )
                  .toList();

        return ProgressChartSection(courses: enrolledCourses);
      },
    );
  }

  void _goToCourse(CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CourseDetailPage(course: course)),
    );
  }

  void _goToCourses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CoursesListPage()),
    );
  }

  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }

  void _goToInfoDesk() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutInfoDeskPage()),
    );
  }

  void _goToNews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BlogNewsPage()),
    );
  }

  void _goToSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportPage()),
    );
  }

  void _goToTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DailyTasksPage()),
    );
  }
}
