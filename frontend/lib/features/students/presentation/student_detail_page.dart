import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/service/supabase_object_storage/object_storage.dart';
import 'package:swaransh_academy/Core/sounds/player.dart';
import 'package:swaransh_academy/Core/widgets/image_picker_field.dart';
import 'package:swaransh_academy/features/payments/presentation/payment_hostory.dart';
import 'package:swaransh_academy/features/students/data/students_notifier.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';
import 'package:swaransh_academy/features/students/widgets/student_avatar.dart';

import '../../../../../Core/theme/app_colors.dart';
import '../../../../../Core/theme/app_spacing.dart';
import '../../../../../Core/theme/app_typography.dart';
import '../../../../../Core/widgets/student_fields_form.dart';

// final editingStudentStatusProvider = StateProvider<String>(
//   (ref) => AppOptions.admissionStatus[0].value,
// );

class StudentDetailPage extends ConsumerStatefulWidget {
  const StudentDetailPage({super.key, required this.studentId});
  final int studentId;

  @override
  ConsumerState<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends ConsumerState<StudentDetailPage> {
  bool _editing = false;
  bool _saving = false;

  String? newStatus;

  // Controllers for every free-text field in StudentFieldsForm
  final _controllers = <String, TextEditingController>{};
  ImagePickerController? _photoController;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _photoController?.dispose();
    super.dispose();
  }

  // Dropdown values
  final _dropdowns = <String, String?>{};

  Student? _loaded;

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

  Student _buildUpdated(Student original, String? imageUrl) {
    final updated = original.copyWith(
      name: _controllers['name']!.text.trim(),
      fatherName: _controllers['fatherName']!.text.trim(),
      status: newStatus ?? original.status,
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
      imageUrl: imageUrl ?? original.imageUrl,
    );
    debugPrint(
      "Updated Student Model , Details page (_buildUpdate function): $updated",
    );
    return updated;
  }

  Future<void> _save(Student original) async {
    debugPrint("SAVE STUDENT CALLED");
    debugPrint(
      "Student userID from Save function of Student detail page:${original.userId}",
    );
    debugPrint(
      "Student ID from Save function of Student detail page:${original.id}",
    );
    //! Student which doesnt have userId can be updated as well.
    // if (original.userId == null) return;
    setState(() => _saving = true);
    debugPrint('Controllers: ${_controllers.keys.toList()}');
    try {
      final oldPath = original.imageUrl;

      final newPath = await _photoController?.upload(
        ref: ref,
        bucket: StorageBucket.studentPhotos,
        pathBuilder: () =>
            StoragePath.studentPhoto(original.id.toString(), 'photo.jpg'),
      );
      // newPath: unchanged path if nothing picked, new path if changed,
      // null if removed, or null if _photoController itself was null.
      final newImageUrl = newPath ?? oldPath;

      debugPrint('INSIDE TRY Controllers: ${_controllers.keys.toList()}');
      await ref
          .read(studentsProvider.notifier)
          .updateStudent(
            _buildUpdated(original, newImageUrl),
            // ^ fall back to oldPath only if controller was genuinely absent —
            //   see note below on whether this fallback is even the right call
          );

      //! DELETE OLD IMAGE
      if (oldPath != null && oldPath.isNotEmpty && oldPath != newPath) {
        try {
          await ref
              .read(supabaseStorageServiceProvider)
              .delete(bucket: StorageBucket.studentPhotos, path: oldPath);
        } catch (e) {
          debugPrint('Old photo cleanup failed (non-fatal): $e');
        }
      }

      if (mounted) {
        setState(() {
          _editing = false;
          _saving = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved')));
      }
    } catch (e) {
      if (mounted) {
        debugPrint("From Student Details Page (_save FUNCTION): $e");
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
            onPressed: () async {
              await AppSounds.playDeleteSound();
              Navigator.pop(ctx, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(studentsProvider.notifier)
          .deleteStudent(student.id!); //! Forced not-null
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete — please try again')),
        );
      }
    }
  }

  void _cancelEdit() {
    _photoController?.discardLocalChanges(); // new method, below
    setState(() => _editing = false);
    // ...whatever else your cancel already does (reverting text controllers etc.)
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

        //* Initilize Photo URL
        _photoController ??= ImagePickerController(
          initialUrl: (student.imageUrl != null && student.imageUrl!.isNotEmpty)
              ? student.imageUrl
              : null,
        );
        debugPrint(
          "======================== Student ID on details Page: ${student.id}",
        );
        debugPrint("Student Name: ${student.name}");
        debugPrint("Image URL: ${student.imageUrl}");

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
                    _cancelEdit();
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
                      (_editing && _photoController != null)
                          ? Center(
                              child: ImagePickerField(
                                controller: _photoController!,
                                label: 'Student Photo',
                                size: 160, // ~ radius 80 * 2
                                shape: BoxShape.circle,
                                resolveDisplayUrl: (path) => ref
                                    .read(supabaseStorageServiceProvider)
                                    .getSignedUrl(
                                      bucket: StorageBucket.studentPhotos,
                                      path: path,
                                    ),
                              ),
                            )
                          : StudentAvatar(student: student, radius: 80),
                      const SizedBox(height: AppSpacing.md),
                      if (student.status != null)
                        _StatusBadge(
                          status: student.status!,
                          isEdit: _editing,
                          onStatusChanged: (status) {
                            newStatus = status;
                          },
                        ),
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
                  isCreate: false,
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
                PaymentHistoryWidget(
                  studentId: student.id!,
                  isAdmin: true, // shows correct/delete actions + add button
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

class _StatusBadge extends StatefulWidget {
  const _StatusBadge({
    required this.status,
    required this.isEdit,
    this.onStatusChanged,
  });

  final String status;
  final bool isEdit;
  final ValueChanged<String>? onStatusChanged;

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
  }

  @override
  void didUpdateWidget(covariant _StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _currentStatus = widget.status;
    }
  }

  void _toggleStatus() {
    // Toggles purely between the valid API enum values
    final nextStatus = _currentStatus == 'active' ? 'inactive' : 'active';

    setState(() {
      _currentStatus = nextStatus;
    });

    widget.onStatusChanged?.call(nextStatus);
  }

  // Maps backend enum keys to human-readable UI labels
  String _getDisplayLabel(String status) {
    return switch (status) {
      'active' => 'ACTIVE',
      'inactive' => 'INACTIVE',
      'pending_payment' => 'PENDING PAYMENT',
      _ => status.replaceAll('_', ' ').toUpperCase(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (_currentStatus) {
      'active' => AppColors.active,
      'pending_payment' => AppColors.pendingPayment,
      _ => AppColors.inactive,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getDisplayLabel(_currentStatus),
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          if (widget.isEdit)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _toggleStatus,
              icon: Icon(
                Icons.switch_left_sharp,
                size: 20,
                color: AppColors.success,
              ),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
