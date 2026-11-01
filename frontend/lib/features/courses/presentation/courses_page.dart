import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/auth/auth_notifier.dart';
import 'package:swaransh_academy/Core/enums/form_fields.dart';

import '../../../Core/auth/user_role.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../../navigation/presentation/app_shell.dart';
import '../data/courses_repository.dart';
import '../domain/course.dart';
import 'widgets/course_card.dart';

class CoursesPage extends ConsumerStatefulWidget {
  const CoursesPage({super.key});

  @override
  ConsumerState<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends ConsumerState<CoursesPage> {
  final _searchCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();
  String _searchQuery = '';
  String? _filterMode;
  String? _filterTag;
  int? _maxFees;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _feesCtrl.dispose();
    super.dispose();
  }

  List<Course> _filteredCourses(List<Course> courses) {
    final search = _searchQuery.trim().toLowerCase();

    return courses.where((course) {
      final matchesSearch =
          search.isEmpty ||
          course.courseName.toLowerCase().contains(search) ||
          course.mapsToSubject.toLowerCase().contains(search);
      final matchesMode =
          _filterMode == null ||
          course.mode.toLowerCase() == _filterMode!.toLowerCase();
      final matchesTag =
          _filterTag == null ||
          course.tag.toLowerCase() == _filterTag!.toLowerCase();
      final matchesFees = _maxFees == null || course.fees <= _maxFees!;

      return matchesSearch && matchesMode && matchesTag && matchesFees;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final role = ref.watch(currentRoleProvider);
    final isAdmin = role == UserRole.admin;
    final isWide = MediaQuery.sizeOf(context).width >= kRailBreakpoint;

    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/home/course/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add Course'),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.textOnGold,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: coursesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (err, _) =>
                  Center(child: Text('Could not load courses: $err')),
              data: (courses) => _buildCourseResults(context, courses, isWide),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final feeFieldWidth = (constraints.maxWidth * 0.28).clamp(
                100.0,
                116.0,
              );
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search by course or subject...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: feeFieldWidth,
                    child: TextField(
                      controller: _feesCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        prefixText: '\u20B9',
                        hintText: 'Max fee',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 12,
                        ),
                        suffixIcon: _feesCtrl.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear fee filter',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 20,
                                  height: 20,
                                ),
                                icon: const Icon(Icons.close, size: 14),
                                onPressed: () {
                                  _feesCtrl.clear();
                                  setState(() => _maxFees = null);
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) => setState(() {
                        _maxFees = int.tryParse(value);
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...AppOptions.learningMode.map(
                  (option) => _filterChip(
                    option: option,
                    selected: _filterMode == option.value,
                    color: AppColors.navy,
                    onSelected: () => setState(() {
                      _filterMode = _filterMode == option.value
                          ? null
                          : option.value;
                    }),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ...AppOptions.courseTag.map(
                  (option) => _filterChip(
                    option: option,
                    selected: _filterTag == option.value,
                    color: AppColors.navy,
                    onSelected: () => setState(() {
                      _filterTag = _filterTag == option.value
                          ? null
                          : option.value;
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required AppOption option,
    required bool selected,
    required Color color,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(
          '${option.label[0].toUpperCase()}${option.label.substring(1)}',
        ),
        selected: selected,
        selectedColor: color.withValues(alpha: 0.16),
        labelStyle: AppTypography.caption.copyWith(
          color: selected ? color : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        onSelected: (_) => onSelected(),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildCourseResults(
    BuildContext context,
    List<Course> courses,
    bool isWide,
  ) {
    final filtered = _filteredCourses(courses);
    if (filtered.isEmpty) {
      return RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.ivory,
        onRefresh: () => ref.read(coursesProvider.notifier).refreshList(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: Center(
                child: Text(
                  courses.isEmpty ? 'No courses yet' : 'No results',
                  style: AppTypography.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isWide) {
      return RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.ivory,
        onRefresh: () => ref.read(coursesProvider.notifier).refreshList(),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 340,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.82,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final course = filtered[index];
            return CourseCard(
              course: course,
              imageHeight: 140,
              onTap: () => _openDetail(context, course.id),
            );
          },
        ),
      );
    }

    final availableHeight =
        MediaQuery.sizeOf(context).height -
        kToolbarHeight -
        MediaQuery.paddingOf(context).top;
    final cardImageHeight = (availableHeight / 2) * 0.55;

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.ivory,
      onRefresh: () => ref.read(coursesProvider.notifier).refreshList(),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final course = filtered[index];
          return CourseCard(
            course: course,
            imageHeight: cardImageHeight.clamp(130, 220),
            onTap: () => _openDetail(context, course.id),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, int courseId) {
    context.push('/home/course/$courseId');
  }
}
