import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/payments/presentation/payment_hostory.dart';
import 'package:swaransh_academy/features/profile/domain/profile.dart';
import 'package:swaransh_academy/features/students/widgets/student_avatar.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../../../Core/theme/staff_line_divider.dart';
import '../../../Core/widgets/student_fields_form.dart';
import '../../profile/data/profile_notifier.dart';
import '../../students/domain/student.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We no longer trigger ScholarNumberDialog here since all profiles
    // are accessible via horizontal swipe.
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (result) {
        if (result.isStudent) {
          final students = result.students ?? [];

          if (students.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('No student profiles found.')),
            );
          }

          // Case 1: Single profile (no swipe tabs needed)
          if (students.length == 1) {
            return RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.ivory,
              onRefresh: () => ref.read(profileProvider.notifier).refreshList(),
              child: _ProfileBody(
                student: students.first,
                hasSiblings: result.hasSiblings,
              ),
            );
          }

          // Case 2: Multiple profiles - WhatsApp classic swipeable TabBar + TabBarView
          return RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.ivory,
            onRefresh: () => ref.read(profileProvider.notifier).refreshList(),

            child: DefaultTabController(
              length: students.length,
              child: Scaffold(
                backgroundColor: AppColors.ivory,
                appBar: AppBar(
                  backgroundColor: AppColors.ivory,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  titleSpacing: AppSpacing.md,
                  title: Text(
                    'Profiles (${students.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.gold),
                      onPressed: () =>
                          ref.read(profileProvider.notifier).refreshList(),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(42),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.divider,
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: AppColors.gold,
                        indicatorWeight: 3.0,
                        labelColor: AppColors.gold,
                        unselectedLabelColor: Colors.black54,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                        tabs: students.map((s) {
                          final label = s.name.isNotEmpty
                              ? s.name
                              : (s.scholarNo ?? 'Profile');
                          return Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(label),
                                if (s.scholarNo != null &&
                                    s.scholarNo!.isNotEmpty) ...[
                                  // const SizedBox(width: 6),
                                  // Container(
                                  //   padding: const EdgeInsets.symmetric(
                                  //     horizontal: 6,
                                  //     vertical: 1,
                                  //   ),
                                  //   decoration: BoxDecoration(
                                  //     color: Colors.black.withOpacity(0.06),
                                  //     borderRadius: BorderRadius.circular(10),
                                  //   ),
                                  //   child: Text(
                                  //     '#${s.scholarNo}',
                                  //     style: const TextStyle(fontSize: 11),
                                  //   ),
                                  // ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                body: TabBarView(
                  children: students.map((student) {
                    return _ProfileBody(
                      key: ValueKey(student.id ?? student.scholarNo),
                      student: student,
                      hasSiblings: true,
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        }

        // Non-student basic profile fallback
        return RefreshIndicator(
          color: AppColors.gold,
          backgroundColor: AppColors.ivory,
          onRefresh: () => ref.read(profileProvider.notifier).refreshList(),
          child: _BasicProfileBody(user: result.userProfile!),
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    super.key,
    required this.student,
    required this.hasSiblings,
  });
  final Student student;
  final bool hasSiblings;

  @override
  Widget build(BuildContext context) {
    final deptColor = AppColors.departmentColor(student.department);

    final controllers = {
      'name': TextEditingController(text: student.name),
      'fatherName': TextEditingController(text: student.fatherName ?? ''),
      'dob': TextEditingController(text: student.dob ?? ''),
      'contact': TextEditingController(text: student.contact ?? ''),
      'email': TextEditingController(text: student.email ?? ''),
      'address': TextEditingController(text: student.address ?? ''),
      'scholarNo': TextEditingController(text: student.scholarNo ?? ''),
      'dateOfJoining': TextEditingController(text: student.dateOfJoining ?? ''),
      'fees': TextEditingController(
        text: student.fees?.toStringAsFixed(0) ?? '',
      ),
      'religion': TextEditingController(text: student.religion ?? ''),
      'caste': TextEditingController(text: student.caste ?? ''),
      'subject': TextEditingController(text: student.subject),
      'startTime': TextEditingController(text: student.startTime),
      'endTime': TextEditingController(text: student.endTime),
    };

    final values = {
      'gender': student.gender,
      'educationQualification': student.educationQualification,
      'department': student.department,
      'admissionType': student.admissionType,
      'learningMode': student.learningMode,
      'batch': student.batch,
      'feeType': student.feeType,
    };

    final studentId = student.id;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(
              student: student,
              deptColor: deptColor,
              hasSiblings: hasSiblings,
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CourseBanner(student: student, deptColor: deptColor),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StudentFieldsForm(
                          isCreate: false,
                          controllers: controllers,
                          values: values,
                          editable: false,
                          lockedFields: const {},
                          visibleSections: const {
                            StudentFieldSection.identity,
                            StudentFieldSection.contact,
                            StudentFieldSection.course,
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Center(child: StaffLineDivider(width: 56)),
                        const SizedBox(height: AppSpacing.lg),
                        _FeesCard(student: student),
                        const SizedBox(height: AppSpacing.lg),

                        // In _ProfileBody, student needs their own ID
                        // student.id is available from the Student model
                        if (studentId != null) ...[
                          PaymentHistoryWidget(
                            studentId: studentId, //? using local variable
                            isAdmin: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.student,
    required this.deptColor,
    required this.hasSiblings,
  });
  final Student student;
  final Color deptColor;
  final bool hasSiblings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + AppSpacing.lg,
        bottom: AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, deptColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2.5),
            ),
            child: StudentAvatar(student: student, radius: 60),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            student.name,
            style: AppTypography.headlineLarge.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            student.subject,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.goldLight,
            ),
          ),

          if (student.scholarNo != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Scholar No. ${student.scholarNo}',
                style: AppTypography.caption.copyWith(color: Colors.white70),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _CourseBanner extends StatelessWidget {
  const _CourseBanner({required this.student, required this.deptColor});
  final Student student;
  final Color deptColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      color: deptColor.withOpacity(0.06),
      child: Row(
        children: [
          Expanded(
            child: _BannerStat(
              label: 'Department',
              value: student.department.replaceAll('_', ' '),
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.divider),
          Expanded(
            child: _BannerStat(label: 'Batch', value: student.batch),
          ),
          Container(width: 1, height: 32, color: AppColors.divider),
          Expanded(
            child: _BannerStat(
              label: 'Timing',
              value: '${student.startTime}–${student.endTime}',
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _FeesCard extends StatelessWidget {
  const _FeesCard({required this.student});
  final Student student;

  @override
  Widget build(BuildContext context) {
    final hasFees = student.fees != null;
    final isPaid = student.feePaidTill != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navy.withOpacity(0.06),
            AppColors.gold.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: AppColors.gold,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Fees', style: AppTypography.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _FeeStat(
                  label: 'Amount',
                  value: hasFees
                      ? '\u20B9${student.fees!.toStringAsFixed(0)}'
                      : '—',
                ),
              ),
              Expanded(
                child: _FeeStat(
                  label: 'Frequency',
                  value: student.feeType?.replaceAll('_', ' ') ?? '—',
                ),
              ),
              Expanded(
                child: _FeeStat(
                  label: 'Paid Till',
                  value: isPaid ? student.feePaidTill! : '—',
                  valueColor: isPaid ? AppColors.active : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pay Fees — coming soon')),
              ),
              icon: const Icon(Icons.payment_outlined, size: 18),
              label: const Text('Pay Fees'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeStat extends StatelessWidget {
  const _FeeStat({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// ── Basic profile for non-linked users ───────────────────────────────────
class _BasicProfileBody extends StatelessWidget {
  const _BasicProfileBody({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final initials = (user.displayName ?? user.email)
        .substring(0, 1)
        .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: CustomScrollView(
        slivers: [
          // Simple hero — no department colour since no student record
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + AppSpacing.lg,
                bottom: AppSpacing.xl,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, AppColors.navyDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.gold.withOpacity(0.2),
                      child: Text(
                        initials,
                        style: AppTypography.headlineLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user.displayName ?? 'User',
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const StaffLineDivider(width: 56),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.ivoryDeep,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          color: AppColors.gold,
                          size: 36,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Not yet enrolled',
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Your account is registered but not yet linked '
                          'to a student record. Submit an admission form '
                          'or contact the academy to activate your profile.',
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
