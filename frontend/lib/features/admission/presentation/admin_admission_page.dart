import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swaransh_academy/features/admission/data/admission_notifier.dart';
import 'package:swaransh_academy/features/admission/domain/admission_form_record.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';

class AdminAdmissionPage extends ConsumerStatefulWidget {
  const AdminAdmissionPage({super.key});

  @override
  ConsumerState<AdminAdmissionPage> createState() => _AdminAdmissionPageState();
}

class _AdminAdmissionPageState extends ConsumerState<AdminAdmissionPage> {
  String _filter =
      'Pending'; // default to pending - what admin cares about most

  @override
  Widget build(BuildContext context) {
    final formsAsync = ref.watch(admissionFormsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admission Requests')),
      body: Column(
        children: [
          // Status filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: ['Pending', 'Approved', 'Declined'].map((status) {
                final selected = _filter == status;
                final color = _statusColor(status);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(status),
                    selected: selected,
                    selectedColor: color.withOpacity(0.15),
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: selected ? color : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _filter = status),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: formsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (e, _) => Center(child: Text('Could not load forms: $e')),
              data: (forms) {
                final filtered = forms
                    .where((f) => f.status == _filter)
                    .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No $_filter applications',
                      style: AppTypography.bodyMedium,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _AdmissionFormCard(
                    form: filtered[i],
                    onApprove: _filter == 'Pending'
                        ? () => _approve(filtered[i])
                        : null,
                    onDecline: _filter == 'Pending'
                        ? () => _decline(filtered[i])
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(AdmissionFormRecord form) async {
    final confirmed = await _confirm(
      context,
      title: 'Approve ${form.name}?',
      body: 'A student record will be created with status Pending Payment.',
      confirmLabel: 'Approve',
      confirmColor: AppColors.active,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(admissionFormsListProvider.notifier).approve(form.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve — please retry')),
        );
      }
    }
  }

  Future<void> _decline(AdmissionFormRecord form) async {
    final confirmed = await _confirm(
      context,
      title: 'Decline ${form.name}?',
      body:
          'The applicant will be notified. No student record will be created.',
      confirmLabel: 'Decline',
      confirmColor: AppColors.error,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(admissionFormsListProvider.notifier).decline(form.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to decline — please retry')),
        );
      }
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: confirmColor),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Color _statusColor(String status) => switch (status) {
    'Approved' => AppColors.active,
    'Declined' => AppColors.error,
    _ => AppColors.pendingPayment,
  };
}

class _AdmissionFormCard extends StatelessWidget {
  const _AdmissionFormCard({
    required this.form,
    this.onApprove,
    this.onDecline,
  });

  final AdmissionFormRecord form;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final deptColor = AppColors.departmentColor(form.department);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        // In _AdmissionFormCard's InkWell onTap:
        context.push('/admission/review', extra: form);
        debugPrint("Nvigating to Full details...");
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: deptColor.withOpacity(0.15),
                    child: Text(
                      form.name.isNotEmpty ? form.name[0].toUpperCase() : '?',
                      style: AppTypography.titleLarge.copyWith(
                        color: deptColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(form.name, style: AppTypography.titleLarge),
                        Text(
                          '${form.department.replaceAll('_', ' ')} · ${form.subject}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: form.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                children: [
                  _InfoChip(Icons.phone_outlined, form.contact),
                  _InfoChip(Icons.email_outlined, form.email),
                  if (form.fees != null)
                    _InfoChip(
                      Icons.currency_rupee,
                      '${form.fees!.toStringAsFixed(0)} / ${form.feeType?.replaceAll('_', ' ') ?? ''}',
                    ),
                ],
              ),
              if (onApprove != null || onDecline != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    if (onDecline != null)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          onPressed: onDecline,
                          child: const Text('Decline'),
                        ),
                      ),
                    if (onApprove != null && onDecline != null)
                      const SizedBox(width: AppSpacing.sm),
                    if (onApprove != null)
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.active,
                          ),
                          onPressed: onApprove,
                          child: const Text('Approve'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Approved' => AppColors.active,
      'Declined' => AppColors.error,
      _ => AppColors.pendingPayment,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
