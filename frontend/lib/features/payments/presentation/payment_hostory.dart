import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/payments/data/payments_notifier.dart';
import 'package:swaransh_academy/features/payments/presentation/add_correct_payment.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../domain/payment.dart';

/// Drop-in replacement for _PaymentHistoryStub.
/// Pass [studentId] from the Student model.
/// [isAdmin] shows correct/delete actions — false for student's own profile.
class PaymentHistoryWidget extends ConsumerWidget {
  const PaymentHistoryWidget({
    super.key,
    required this.studentId,
    this.isAdmin = false,
  });

  final int studentId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Header ----
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.history, size: 18),
              color: AppColors.gold,
              onPressed: () async {
                await ref.read(paymentProvider(studentId).notifier).refresh();
                debugPrint("Refresh Payment History");
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Payment History', style: AppTypography.titleLarge),
            const Spacer(),
            if (isAdmin)
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.gold,
                  size: 22,
                ),
                tooltip: 'Record payment',
                onPressed: () => _openAddSheet(context),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ---- Content ----
        paymentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          ),
          error: (e, _) => _EmptyCard(
            icon: Icons.error_outline,
            message: 'Could not load payments: $e',
            color: AppColors.error,
          ),
          data: (payments) {
            // Only show active rows to students; admin sees all
            final visible = isAdmin
                ? payments
                : payments.where((p) => p.isActive!).toList();

            if (visible.isEmpty) {
              return const _EmptyCard(
                icon: Icons.receipt_long_outlined,
                message: 'No payment records yet.',
              );
            }

            return Column(
              children: visible.map((p) {
                debugPrint("From payment History , Line 87: ${p.toJson()}");
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PaymentRow(
                    payment: p,
                    supersededBy: p.supersededBy,
                    isAdmin: isAdmin,
                    onCorrect: isAdmin
                        ? () => _openCorrectSheet(context, p)
                        : null,
                    onDelete: isAdmin
                        ? () => _confirmDelete(context, ref, p)
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _openAddSheet(BuildContext context) {
    AddPaymentSheet.show(context, studentId: studentId);
  }

  void _openCorrectSheet(BuildContext context, Payment p) {
    AddPaymentSheet.show(context, studentId: studentId, existing: p);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Payment p,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete payment?'),
        content: const Text(
          'This is a hard delete for genuine duplicates only.\n'
          'Use "Correct" to fix a wrong entry instead.',
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
    if (confirmed != true) return;
    try {
      await ref
          .read(paymentProvider(studentId).notifier)
          .remove(p.id!); //! Forced non null
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}

// ---- Single payment row -----------------------------------------------

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.isAdmin,
    this.supersededBy,
    this.onCorrect,
    this.onDelete,
  });

  final Payment payment;
  final bool isAdmin;
  final int? supersededBy;
  final VoidCallback? onCorrect;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isSuperseded = (supersededBy != null); //! Foreced non null
    final typeColor = _typeColor(payment.paymentType!); //! Same

    return Opacity(
      opacity: isSuperseded ? 0.45 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSuperseded
                ? AppColors.divider
                : typeColor.withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Type indicator
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: isSuperseded ? AppColors.divider : typeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          payment.paymentType!
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSuperseded
                                ? AppColors.textSecondary
                                : typeColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (isSuperseded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              'SUPERSEDED',
                              style: AppTypography.caption.copyWith(
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${payment.mode!.replaceAll('_', ' ')} · ${_formatDate(payment.paidOn!)}',
                      style: AppTypography.caption,
                    ),
                    if (payment.txnRef != null)
                      Text(
                        'Ref: ${payment.txnRef}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              // Amount
              Text(
                '\u20B9${payment.amount!.toStringAsFixed(0)}',
                style: AppTypography.titleLarge.copyWith(
                  color: isSuperseded
                      ? AppColors.textSecondary
                      : AppColors.navy,
                ),
              ),

              // Admin actions
              if (isAdmin && payment.isActive!) ...[
                const SizedBox(width: AppSpacing.xs),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'correct',
                      child: Text('Correct (supersede)'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete (duplicate only)',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'correct') onCorrect?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) => switch (type) {
    'admission' => AppColors.deptActing,
    'monthly' => AppColors.active,
    'quarterly' => AppColors.deptProduction,
    'half_yearly' => AppColors.gold,
    'yearly' => AppColors.navy,
    _ => AppColors.textSecondary,
  };

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return iso.split('T').first;
    }
  }
}

// ---- Empty / error state -----------------------------------------------

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.message,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.ivoryDeep,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: color.withOpacity(0.5)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
