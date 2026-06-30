import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/features/students/students_page.dart';

import '../../admission/presentation/admission_page.dart';
import '../../courses/data/courses_repository.dart';
import '../../courses/presentation/course_detail_page.dart';
import '../../courses/presentation/course_form_page.dart';
import '../../courses/presentation/courses_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../splash/presentation/splash_page.dart';
import '../presentation/app_shell.dart';
import '../presentation/chat_assistant_overlay.dart';

/// Branch order here MUST match kAllDestinations order in
/// nav_destinations.dart - both drive index-based navigation off the same
/// list. If you add/reorder a destination, mirror it here.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ChatAssistantOverlay(
            child: AppShell(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const CoursesPage(),
                routes: [
                  GoRoute(
                    path: 'course/new',
                    builder: (_, __) => const CourseFormPage(),
                  ),
                  GoRoute(
                    path: 'course/:id',
                    builder: (_, state) => CourseDetailPage(
                      courseId: int.parse(state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final id = int.parse(state.pathParameters['id']!);
                          final course = ProviderScope.containerOf(
                            context,
                          ).read(coursesProvider.notifier).findById(id);
                          return CourseFormPage(existing: course);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/students',
                builder: (_, __) => const StudentsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admission',
                builder: (_, __) => const AdmissionPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfilePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
