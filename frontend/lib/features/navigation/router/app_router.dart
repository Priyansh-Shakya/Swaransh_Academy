import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/features/admission/domain/admission_form_record.dart';
import 'package:swaransh_academy/features/admission/presentation/admin_admission_detail_page.dart';
import 'package:swaransh_academy/features/admission/presentation/admission_form_screen.dart';
import 'package:swaransh_academy/features/admission/presentation/admission_payment_screen.dart';
import 'package:swaransh_academy/features/admission/presentation/admission_success_screen.dart';
import 'package:swaransh_academy/features/admission/presentation/admission_terms_screen.dart';
import 'package:swaransh_academy/features/payments/presentation/student_payment_screen.dart';
import 'package:swaransh_academy/features/auth/presentation/auth_screen.dart';
import 'package:swaransh_academy/features/role_select/presentation/role_select_page.dart';

import '../../admission/presentation/admission_page.dart';
import '../../courses/data/courses_repository.dart';
import '../../courses/presentation/course_detail_page.dart';
import '../../courses/presentation/course_form_page.dart';
import '../../courses/presentation/courses_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../settings/presentation/about_academy_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../splash/presentation/splash_page.dart';
import '../../students/presentation/student_create_page.dart';
import '../../students/presentation/student_detail_page.dart';
import '../../students/presentation/students_page.dart';
import '../presentation/app_shell.dart';
import '../presentation/chat_assistant_overlay.dart';

/// Branch order here MUST match kAllDestinations order in
/// nav_destinations.dart - both drive index-based navigation off the same
/// list. If you add/reorder a destination, mirror it here.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    // redirect: (context, state) {
    //   debugPrint("Router Redirect Called");
    //   final isSignedIn = ref.watch(isSignedInProvider);
    //   final isOnAuth = state.matchedLocation == '/auth';
    //   final isOnRoleSelect = state.matchedLocation == '/role-select';

    //   debugPrint("Is signed in: $isSignedIn");
    //   // Don't auto-redirect while AuthScreen is mid-flow (signup role write,
    //   // refreshRole, admin verification, etc.) — it will navigate itself via onSuccess.
    //   final authInProgress = ref.read(authProvider.notifier).authFlowInProgress;
    //   if (authInProgress) return null;

    //   if (isSignedIn && (isOnRoleSelect || isOnAuth)) return '/home';
    //   return null;
    // },
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
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const StudentCreatePage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => StudentDetailPage(
                      studentId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
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
                routes: [
                  GoRoute(
                    path: 'about',
                    builder: (_, __) => const AboutAcademyPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admission',
                builder: (_, __) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'form',
                    builder: (_, __) => const AdmissionFormScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admission/form',
        builder: (_, __) => const AdmissionFormScreen(),
      ),
      GoRoute(
        path: '/admission/terms',
        builder: (_, __) => const AdmissionTermsScreen(),
      ),
      GoRoute(
        path: '/admission/payment',
        builder: (_, __) => const AdmissionPaymentScreen(),
      ),
      GoRoute(
        path: '/admission/success',
        builder: (_, __) => const AdmissionSuccessScreen(),
      ),
      // Add these two routes alongside the existing /admission/form, /admission/terms etc:
      GoRoute(
        path: '/admission/pay',
        builder: (context, state) =>
            StudentPaymentScreen(form: state.extra as AdmissionFormRecord),
      ),
      GoRoute(
        path: '/admission/review',
        builder: (context, state) =>
            AdminAdmissionDetailPage(form: state.extra as AdmissionFormRecord),
      ),
      // Routes to add alongside /splash (top-level, outside StatefulShellRoute):
      GoRoute(path: '/role-select', builder: (_, __) => const RoleSelectPage()),
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          final onSuccess = state.extra as VoidCallback?;
          return AuthScreen(onSuccess: onSuccess);
        },
      ),
    ],
  );
});
