import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/payments/data/online_payment_notifier.dart';

/// Keeps your own button styling via [builder]; all payment logic lives in the notifier.
class PayFeesButton extends ConsumerWidget {
  const PayFeesButton({
    super.key,
    required this.studentId,
    required this.builder,
    this.cycles = 1,
    this.onPaid,
    this.isDue = true,
  });

  final int studentId;
  final int cycles;
  final bool isDue;

  /// Called once when the payment is confirmed (e.g. to refresh payment history).
  final VoidCallback? onPaid;

  final Widget Function(BuildContext context, VoidCallback? onTap, bool loading)
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = onlinePaymentProvider(studentId);
    final feeStatus = ref.watch(feeStatusProvider(studentId)).valueOrNull;
    final effectiveIsDue = feeStatus?.isDue ?? isDue;

    ref.listen<AsyncValue<PaymentFlowState>>(provider, (previous, next) {
      final current = next.valueOrNull;
      final before = previous?.valueOrNull;
      if (current == null || current.phase == before?.phase) return;

      String? message;
      switch (current.phase) {
        case PaymentPhase.paid:
          message = 'Payment successful';
          onPaid?.call();
          break;
        case PaymentPhase.pending:
        case PaymentPhase.failed:
          message = current.message;
          break;
        default:
          break;
      }
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final busy = ref.watch(provider).valueOrNull?.busy ?? false;

    final VoidCallback? onTapHandler = busy
        ? null
        : () {
            if (!effectiveIsDue) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You have already paid for this month!'),
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
            ref.read(provider.notifier).pay(cycles: cycles);
          };

    return builder(
      context,
      onTapHandler,
      busy,
    );
  }
}
