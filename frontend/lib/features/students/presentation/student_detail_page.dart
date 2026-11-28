import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/Core/service/supabase_object_storage/object_storage.dart';
import 'package:swaransh_academy/Core/sounds/player.dart';
import 'package:swaransh_academy/Core/widgets/image_picker_field.dart';
import 'package:swaransh_academy/features/payments/data/online_payment_notifier.dart';
import 'package:swaransh_academy/features/payments/data/razorpay_api_service.dart';
import 'package:swaransh_academy/features/payments/presentation/payment_hostory.dart';
import 'package:swaransh_academy/features/students/data/students_notifier.dart';
import 'package:swaransh_academy/features/students/domain/student.dart';
import 'package:swaransh_academy/features/students/widgets/student_avatar.dart';

import '../../../../../Core/theme/app_colors.dart';
import '../../../../../Core/theme/app_spacing.dart';
import '../../../../../Core/theme/app_typography.dart';
import '../../../../../Core/theme/staff_line_divider.dart';
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final avatarSection = Column(
                children: [
                  (_editing && _photoController != null)
                      ? Center(
                          child: ImagePickerField(
                            controller: _photoController!,
                            label: 'Student Photo',
                            size: 160,
                            shape: BoxShape.circle,
                            resolveDisplayUrl: (path) => ref
                                .read(supabaseStorageServiceProvider)
                                .getSignedUrl(
                                  bucket: StorageBucket.studentPhotos,
                                  path: path,
                                ),
                          ),
                        )
                      : StudentAvatar(student: student, radius: 72),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    student.name,
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (student.scholarNo != null)
                    Text(
                      'Scholar No. ${student.scholarNo}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  if (student.status != null)
                    _StatusBadge(
                      status: student.status!,
                      isEdit: _editing,
                      onStatusChanged: (status) {
                        newStatus = status;
                      },
                    ),
                ],
              );

              final detailsSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudentFieldsForm(
                    isCreate: false,
                    controllers: _controllers,
                    values: _dropdowns,
                    editable: _editing,
                    lockedFields: const {},
                    avatarHeader: avatarSection,
                    imagePickerController: _editing ? _photoController : null,
                    onDropdownChanged: (key, value) =>
                        setState(() => _dropdowns[key] = value),
                  ),
                  if (student.id != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _AdminFeeSection(studentId: student.id!),
                    const SizedBox(height: AppSpacing.xl),
                    const StaffLineDivider(width: 56),
                    const SizedBox(height: AppSpacing.xl),
                    PaymentHistoryWidget(
                      studentId: student.id!,
                      isAdmin: true,
                    ),
                  ],
                ],
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: detailsSection,
              );
            },
          ),
        );
      },
    );
  }
}

class _AdminFeeSection extends ConsumerWidget {
  const _AdminFeeSection({required this.studentId});
  final int studentId;

  Future<int?> _showAmountDialog(
      BuildContext context, int cycleBalance, int? currentAmount) async {
    final ctrl = TextEditingController(
      text: (currentAmount ?? (cycleBalance > 1 ? cycleBalance - 1 : 1))
          .toString(),
    );
    final formKey = GlobalKey<FormState>();

    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Approved Part Payment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Approved Amount (\u20B9)',
                  helperText: 'Balance is \u20B9$cycleBalance',
                  prefixText: '\u20B9 ',
                ),
                validator: (val) {
                  final n = int.tryParse(val ?? '');
                  if (n == null || n < 1) {
                    return 'Enter an amount of at least \u20B91';
                  }
                  if (n >= cycleBalance) {
                    return 'Amount must be less than balance (\u20B9$cycleBalance)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final amt = int.parse(ctrl.text.trim());
                Navigator.pop(ctx, amt);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeStatusAsync = ref.watch(feeStatusProvider(studentId));

    return feeStatusAsync.when(
      loading: () => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
          ),
        ),
      ),
      error: (err, _) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Could not load fee status: $err',
                style: AppTypography.caption.copyWith(color: AppColors.error),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () => ref.invalidate(feeStatusProvider(studentId)),
            ),
          ],
        ),
      ),
      data: (feeStatus) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final isStarted = !feeStatus.cycleStart.isAfter(today);
        final balanceColor = feeStatus.cycleBalance == 0
            ? AppColors.active
            : (isStarted ? AppColors.error : AppColors.textPrimary);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
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
                  Text('Billing Cycle & Partial Payment',
                      style: AppTypography.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Cycle:', style: AppTypography.caption),
                  Text(feeStatus.cycleLabel,
                      style: AppTypography.bodySmall
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Paid in Cycle:', style: AppTypography.caption),
                  Text(
                      '\u20B9${feeStatus.cyclePaid} of \u20B9${feeStatus.cycleFee}',
                      style: AppTypography.bodySmall
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Balance due:', style: AppTypography.caption),
                  Text(
                    '\u20B9${feeStatus.cycleBalance}',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
              if (feeStatus.hasUnlinkedPayments) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Some payments are not linked to a cycle.',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.gold),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: AppSpacing.lg),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow part payment for this cycle'),
                subtitle: const Text(
                    'The student can pay this amount once. It switches off after their payment or when the cycle is fully paid.'),
                value: feeStatus.allowPartialPayment,
                activeThumbColor: AppColors.gold,
                onChanged: (val) async {
                  if (val) {
                    if (feeStatus.cycleBalance <= 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Cycle balance must be greater than \u20B91 to allow a part payment.')),
                      );
                      return;
                    }
                    final amt = await _showAmountDialog(
                        context, feeStatus.cycleBalance, feeStatus.partialPaymentAmount);
                    if (amt == null) return;
                    try {
                      await ref
                          .read(razorpayApiServiceProvider)
                          .togglePartialPayment(
                              studentId: studentId, allow: true, amount: amt);
                      ref.invalidate(feeStatusProvider(studentId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update: $e')),
                        );
                      }
                    }
                  } else {
                    try {
                      await ref
                          .read(razorpayApiServiceProvider)
                          .togglePartialPayment(
                              studentId: studentId, allow: false, amount: null);
                      ref.invalidate(feeStatusProvider(studentId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update: $e')),
                        );
                      }
                    }
                  }
                },
              ),
              if (feeStatus.allowPartialPayment && feeStatus.partialPaymentAmount != null) ...[
                Row(
                  children: [
                    Text(
                      'Approved part payment: \u20B9${feeStatus.partialPaymentAmount}',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16, color: AppColors.gold),
                      tooltip: 'Change approved amount',
                      onPressed: () async {
                        final amt = await _showAmountDialog(
                            context, feeStatus.cycleBalance, feeStatus.partialPaymentAmount);
                        if (amt == null) return;
                        try {
                          await ref
                              .read(razorpayApiServiceProvider)
                              .togglePartialPayment(
                                  studentId: studentId, allow: true, amount: amt);
                          ref.invalidate(feeStatusProvider(studentId));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ],
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
