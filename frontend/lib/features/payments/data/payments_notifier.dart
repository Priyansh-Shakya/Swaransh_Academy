import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/features/payments/data/payments_api_service.dart';
import 'package:swaransh_academy/features/payments/domain/payment.dart';

/// Notifier for managing payments via real API.
class PaymentsNotifier extends AsyncNotifier<List<Payment>> {
  late int _studentId;

  /// Initialize with student ID for payment operations.
  void init(int studentId) {
    _studentId = studentId;
  }

  @override
  Future<List<Payment>> build() async {
    // This will be overridden when init() is called
    return [];
  }

  /// Load payment history for a specific student.
  Future<void> loadPayments(int studentId) async {
    _studentId = studentId;
    state = const AsyncValue.loading();
    try {
      final payments = await ref
          .read(paymentsApiServiceProvider)
          .getPaymentHistory(studentId);
      state = AsyncValue.data(payments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Record a new payment.
  Future<void> recordPayment(Payment payment) async {
    final previous = state;
    final current = state.valueOrNull ?? [];

    state = AsyncValue.data([...current, payment]);

    try {
      final created = await ref
          .read(paymentsApiServiceProvider)
          .createPayment(_studentId, payment);
      state = AsyncValue.data([...current, created]);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  /// Correct a payment (supersede).
  Future<void> correctPayment(int paymentId, Payment corrected) async {
    final previous = state;
    final current = state.valueOrNull ?? [];

    state = AsyncValue.data([
      for (final p in current)
        if (p.id == paymentId) corrected else p,
    ]);

    try {
      await ref
          .read(paymentsApiServiceProvider)
          .correctPayment(_studentId, paymentId, corrected);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  /// Delete a payment.
  Future<void> deletePayment(int paymentId) async {
    final previous = state;
    final current = state.valueOrNull ?? [];

    state = AsyncValue.data(current.where((p) => p.id != paymentId).toList());

    try {
      await ref
          .read(paymentsApiServiceProvider)
          .deletePayment(_studentId, paymentId);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Payment? findById(int id) {
    final current = state.valueOrNull ?? [];
    for (final p in current) {
      if (p.id == id) return p;
    }
    return null;
  }
}

final paymentsProvider = AsyncNotifierProvider<PaymentsNotifier, List<Payment>>(
  PaymentsNotifier.new,
);

// Mock data kept for reference/testing
final List<Payment> _mockPayments = [
  const Payment(
    id: 1,
    studentId: 1,
    amount: 2500,
    feeType: 'Monthly',
    paymentDate: '2026-01-15',
    status: 'Completed',
    modeOfPayment: 'UPI',
    receiptNo: 'REC-001',
  ),
  const Payment(
    id: 2,
    studentId: 1,
    amount: 2500,
    feeType: 'Monthly',
    paymentDate: '2026-02-15',
    status: 'Completed',
    modeOfPayment: 'Bank_Transfer',
    receiptNo: 'REC-002',
  ),
];
