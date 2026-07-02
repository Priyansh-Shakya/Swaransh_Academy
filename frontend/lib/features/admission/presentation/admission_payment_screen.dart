import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../../../Core/theme/staff_line_divider.dart';
import '../data/admission_notifier.dart';

const _paymentModes = ['UPI', 'Cash', 'Card', 'Bank_Transfer'];

class AdmissionPaymentScreen extends ConsumerStatefulWidget {
  const AdmissionPaymentScreen({super.key});

  @override
  ConsumerState<AdmissionPaymentScreen> createState() =>
      _AdmissionPaymentScreenState();
}

class _AdmissionPaymentScreenState
    extends ConsumerState<AdmissionPaymentScreen> {
  String _selectedMode = 'UPI';

  Future<void> _submit() async {
    try {
      await ref.read(admissionFormProvider.notifier).submit();
      if (mounted) context.go('/admission/success');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Submission failed — please try again')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(admissionFormProvider);
    final isSubmitting = formState.isSubmitting;
    final fees = formState.fees;
    final feeType = formState.feeType?.replaceAll('_', ' ') ?? '';

    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppColors.ivory,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _StepIndicator(current: 3, total: 3),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review & Pay', style: AppTypography.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Confirm your application details and complete payment.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ---- Application summary card ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Application Summary',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.gold,
                      )),
                  const SizedBox(height: AppSpacing.md),
                  _SummaryRow('Applicant', formState.name),
                  _SummaryRow('Department',
                      formState.department.replaceAll('_', ' ')),
                  _SummaryRow('Subject', formState.subject),
                  _SummaryRow('Mode', formState.learningMode),
                  _SummaryRow('Batch',
                      '${formState.batch} · ${formState.startTime}–${formState.endTime}'),
                  const SizedBox(height: AppSpacing.md),
                  const Center(child: StaffLineDivider(width: 40)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fee Amount',
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        fees != null
                            ? '\u20B9${fees.toStringAsFixed(0)} / $feeType'
                            : '—',
                        style: AppTypography.headlineMedium
                            .copyWith(color: AppColors.navy),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ---- Payment mode ----
            Text('Payment Method', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _paymentModes.map((mode) {
                final selected = _selectedMode == mode;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMode = mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.navy
                          : Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: selected ? AppColors.navy : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      mode.replaceAll('_', ' '),
                      style: AppTypography.bodyMedium.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_selectedMode == 'UPI') ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.ivoryDeep,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'UPI gateway integration coming soon. '
                        'For now, please pay at the academy and '
                        'admin will confirm your payment manually.',
                        style: AppTypography.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Text('Submit Application'),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: AppTypography.label),
          const Spacer(),
          Text(
            value.isEmpty ? '—' : value,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: List.generate(total, (i) {
          final active = i < current;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: active ? AppColors.gold : AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          );
        }),
      ),
    );
  }
}
