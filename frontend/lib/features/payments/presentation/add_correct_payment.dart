import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/payments/data/payments_notifier.dart';

import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_spacing.dart';
import '../../../Core/theme/app_typography.dart';
import '../domain/payment.dart';

/// Bottom sheet for admin to add a new payment or correct an existing one.
/// Pass [existing] to pre-fill for correction (supersede flow).
class AddPaymentSheet extends ConsumerStatefulWidget {
  const AddPaymentSheet({super.key, required this.studentId, this.existing});

  final int studentId;
  final Payment? existing; // non-null = correction mode

  static Future<void> show(
    BuildContext context, {
    required int studentId,
    Payment? existing,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPaymentSheet(studentId: studentId, existing: existing),
    );
  }

  @override
  ConsumerState<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

const kPaymentTypes = ['monthly', 'quarterly', 'half_yearly', 'yearly'];
const kPaymentModes = ['UPI', 'Cash', 'Card', 'Bank_Transfer'];
const kPaymentCategories = ['fee', 'admission', 'other'];

class _AddPaymentSheetState extends ConsumerState<AddPaymentSheet> {
  late String _type = widget.existing?.paymentType ?? kPaymentTypes.first;
  late String _mode = widget.existing?.mode ?? kPaymentModes.first;
  late String _category =
      widget.existing?.payment_category ?? kPaymentCategories.first;

  final _amountCtrl = TextEditingController();
  final _txnCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  bool _saving = false;
  bool get _isCorrection => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _amountCtrl.text = (widget.existing!.amount ?? 0).toStringAsFixed(2);
      _txnCtrl.text = widget.existing!.txnRef ?? '';
      _dateCtrl.text = (widget.existing!.paidOn ?? '').split('T').first;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _txnCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountCtrl.text.trim();
    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _saving = true);

    final body = PaymentCreate(
      paymentType: _type,
      payment_category: _category,
      amount: double.parse(amountText),
      mode: _mode,
      isActive: true,
      txnRef: _txnCtrl.text.trim().isEmpty ? null : _txnCtrl.text.trim(),
      paidOn: _dateCtrl.text.trim().isEmpty
          ? null
          : '${_dateCtrl.text.trim()}T00:00:00+00:00',
    );

    try {
      if (_isCorrection) {
        final existingId = widget.existing!.id;
        if (existingId == null)
          return; // shouldn't happen for a fetched payment, but guards the UI
        await ref
            .read(paymentProvider(widget.studentId).notifier)
            .correct(existingId, body);
      } else {
        await ref.read(paymentProvider(widget.studentId).notifier).add(body);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _isCorrection ? 'Correct Payment' : 'Record Payment',
              style: AppTypography.headlineMedium,
            ),
            if (_isCorrection) ...[
              const SizedBox(height: 4),
              Text(
                'A corrected row will be created. '
                'The original will be marked as superseded.',
                style: AppTypography.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Payment type
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Payment Type'),
              items: kPaymentTypes
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.replaceAll('_', ' ').toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Payment Category'),
              items: kPaymentCategories
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.replaceAll('_', ' ').toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: AppSpacing.md),
            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (\u20B9)',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Mode
            DropdownButtonFormField<String>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Payment Mode'),
              items: kPaymentModes
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _mode = v!),
            ),
            const SizedBox(height: AppSpacing.md),

            // Date (optional — for backfilling)
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date (optional — for backfilling)',
                hintText: 'Tap to pick',
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                helperText: 'Leave blank to use today\'s date.',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  _dateCtrl.text =
                      '${picked.year.toString().padLeft(4, '0')}-'
                      '${picked.month.toString().padLeft(2, '0')}-'
                      '${picked.day.toString().padLeft(2, '0')}';
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Txn ref (optional)
            TextFormField(
              controller: _txnCtrl,
              decoration: const InputDecoration(
                labelText: 'Transaction Reference (optional)',
                hintText: 'UPI ID, cheque no. etc.',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isCorrection ? 'Save Correction' : 'Record Payment',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
