import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/features/students/data/students_notifier.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';
import 'package:swaransh_academy/features/students/widgets/student_avatar.dart';

import '../../../../../Core/theme/app_colors.dart';
import '../../../../../Core/theme/app_spacing.dart';
import '../../../../../Core/theme/app_typography.dart';
import '../../../../../Core/widgets/student_fields_form.dart';

class StudentDetailPage extends ConsumerStatefulWidget {
  const StudentDetailPage({super.key, required this.studentId});
  final int studentId;

  @override
  ConsumerState<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends ConsumerState<StudentDetailPage> {
  bool _editing = false;
  bool _saving = false;

  // Controllers for every free-text field in StudentFieldsForm
  final _controllers = <String, TextEditingController>{};

  // Dropdown values
  final _dropdowns = <String, String?>{};

  Student? _loaded;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(Student s) {
    void c(String key, String? value) {
      _controllers[key] = TextEditingController(text: value ?? '');
    }

    c('name', s.name);
    c('fatherName', s.fatherName);
    c('dob', s.dob);
    c('contact', s.contact);
    c('email', s.email);
    c('address', s.address);
    c('scholarNo', s.scholarNo);
    c('dateOfJoining', s.dateOfJoining);
    c('fees', s.fees?.toStringAsFixed(0));
    c('religion', s.religion);
    c('caste', s.caste);
    c('subject', s.subject);
    c('startTime', s.startTime);
    c('endTime', s.endTime);

    _dropdowns['gender'] = s.gender;
    _dropdowns['educationQualification'] = s.educationQualification;
    _dropdowns['department'] = s.department;
    _dropdowns['admissionType'] = s.admissionType;
    _dropdowns['learningMode'] = s.learningMode;
    _dropdowns['batch'] = s.batch;
    _dropdowns['feeType'] = s.feeType;
    _dropdowns['status'] = s.status;
  }

  Student _buildUpdated(Student original) {
    return original.copyWith(
      name: _controllers['name']!.text.trim(),
      fatherName: _controllers['fatherName']!.text.trim(),
      dob: _controllers['dob']!.text.trim(),
      contact: _controllers['contact']!.text.trim(),
      email: _controllers['email']!.text.trim(),
      address: _controllers['address']!.text.trim(),
      scholarNo: _controllers['scholarNo']!.text.trim(),
      dateOfJoining: _controllers['dateOfJoining']!.text.trim(),
      fees: double.tryParse(_controllers['fees']!.text.trim()),
      religion: _controllers['religion']!.text.trim(),
      caste: _controllers['caste']!.text.trim(),
      subject: _controllers['subject']!.text.trim(),
      startTime: _controllers['startTime']!.text.trim(),
      endTime: _controllers['endTime']!.text.trim(),
      gender: _dropdowns['gender'],
      educationQualification: _dropdowns['educationQualification'],
      department: _dropdowns['department'] ?? original.department,
      admissionType: _dropdowns['admissionType'] ?? original.admissionType,
      learningMode: _dropdowns['learningMode'] ?? original.learningMode,
      batch: _dropdowns['batch'] ?? original.batch,
      feeType: _dropdowns['feeType'],
    );
  }

  Future<void> _save(Student original) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(studentsProvider.notifier)
          .updateStudent(_buildUpdated(original));
      if (mounted) {
        setState(() {
          _editing = false;
          _saving = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save — changes reverted')),
        );
      }
    }
  }

  Future<void> _delete(Student student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text(
          '"${student.name}" will be permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(studentsProvider.notifier).deleteStudent(student.id);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete — please try again')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return studentsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (students) {
        final student = students
            .where((s) => s.id == widget.studentId)
            .firstOrNull;
        if (student == null) {
          return const Scaffold(body: Center(child: Text('Student not found')));
        }

        // Initialise controllers once when student data first loads.
        if (_loaded?.id != student.id) {
          _loaded = student;
          _initControllers(student);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_editing ? 'Editing: ${student.name}' : student.name),
            actions: [
              if (!_editing) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () => setState(() => _editing = true),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: () => _delete(student),
                ),
              ] else ...[
                TextButton(
                  onPressed: () => setState(() {
                    _editing = false;
                    _initControllers(student); // reset to saved state
                  }),
                  child: const Text('Cancel'),
                ),
                _saving
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: () => _save(student),
                        child: Text(
                          'Save',
                          style: TextStyle(color: AppColors.gold),
                        ),
                      ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: avatar + name + status
                Center(
                  child: Column(
                    children: [
                      StudentAvatar(student: student, radius: 48),
                      const SizedBox(height: AppSpacing.md),
                      if (student.status != null)
                        _StatusBadge(status: student.status!),
                      if (student.scholarNo != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Scholar No. ${student.scholarNo}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Main form widget (shared with Profile + Admission)
                StudentFieldsForm(
                  controllers: _controllers,
                  values: _dropdowns,
                  editable: _editing,
                  // Admin can edit everything - no locked fields.
                  lockedFields: const {},
                  onDropdownChanged: (key, value) =>
                      setState(() => _dropdowns[key] = value),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Payments stub - structural placeholder only
                Text('Payment History', style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.ivoryDeep,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    'Payment records will appear here.',
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => AppColors.active,
      'pending_payment' => AppColors.pendingPayment,
      _ => AppColors.inactive,
    };
    final label = status.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
