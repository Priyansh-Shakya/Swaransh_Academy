import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/auth/auth_notifier.dart';
import 'package:swaransh_academy/Core/enums/form_fields.dart';
import 'package:swaransh_academy/features/students/data/students_notifier.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';

import '../../../../Core/auth/user_role.dart';
import '../../../../Core/theme/app_colors.dart';
import '../../../../Core/theme/app_spacing.dart';
import '../../../../Core/theme/app_typography.dart';
import '../widgets/student_basic_sheet.dart';
import '../widgets/student_list_tile.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _filterDept;
  String? _filterBatch;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Student> _filtered(List<Student> all) {
    return all.where((s) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.subject.toLowerCase().contains(q);
      final matchesDept = _filterDept == null || s.department == _filterDept;
      final matchesBatch = _filterBatch == null || s.batch == _filterBatch;
      return matchesSearch && matchesDept && matchesBatch;
    }).toList();
  }

  void _onTap(BuildContext context, Student student, UserRole role) {
    debugPrint("Student ID: ${student.id}");
    debugPrint("Navigating to Students Details...\n${student.toJson()}");
    if (role == UserRole.admin) {
      context.push('/students/${student.id}');
    } else {
      StudentBasicSheet.show(context, student);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final role = ref.watch(currentRoleProvider);
    final isAdmin = role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  tooltip: 'Add Student',
                  onPressed: () => context.push('/students/new'),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name or subject...',
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
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._deptFilters(),
                        const SizedBox(width: AppSpacing.xs),
                        ..._batchFilters(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (e, _) {
                if (e.toString().contains('No Student Found')) {
                  return Center(child: Text('No Student Found'));
                }
                return Center(child: Text('Could not load students: $e'));
              },
              data: (students) {
                final filtered = _filtered(students);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      students.isEmpty ? 'No students yet' : 'No results',
                      style: AppTypography.bodyMedium,
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.ivory,
                  onRefresh: () =>
                      ref.read(studentsProvider.notifier).refreshList(),
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => StudentListTile(
                      student: filtered[i],
                      onTap: () => _onTap(context, filtered[i], role),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _deptFilters() {
    return AppOptions.department.map((option) {
      final selected = _filterDept == option.value;
      final color = AppColors.departmentColor(option.value);

      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: FilterChip(
          label: Text(option.label),
          selected: selected,
          selectedColor: color.withOpacity(0.18),
          labelStyle: AppTypography.caption.copyWith(
            color: selected ? color : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          onSelected: (_) {
            setState(() {
              _filterDept = selected ? null : option.value;
            });
          },
          showCheckmark: false,
        ),
      );
    }).toList();
  }

  List<Widget> _batchFilters() {
    return AppOptions.batch.map((option) {
      final selected = _filterBatch == option.value;

      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: FilterChip(
          label: Text(option.label),
          selected: selected,
          selectedColor: AppColors.navy.withOpacity(0.12),
          labelStyle: AppTypography.caption.copyWith(
            color: selected ? AppColors.navy : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          onSelected: (_) {
            setState(() {
              _filterBatch = selected ? null : option.value;
            });
          },
          showCheckmark: false,
        ),
      );
    }).toList();
  }
}
