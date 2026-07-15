import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/payments/data/provider.dart';
import 'package:swaransh_academy/features/payments/domain/payment.dart';

/// Feature-specific API service for payments.
class PaymentsApiService {
  PaymentsApiService(this._apiService);

  final ApiService<Payment> _apiService;

  /// Get payment history for a student.
  Future<List<Payment>> getPaymentHistory(int studentId) {
    return _apiService.getAll(endpoint: '/student/$studentId/paymentList');
  }

  /// Record a new payment.
  Future<Payment> createPayment(int studentId, Payment payment) {
    final payload = Map<String, dynamic>.from(payment.toJson())
      ..remove('id')
      ..remove('student_id');
    return _apiService.create(
      endpoint: '/student/$studentId/payment',
      data: payload,
    );
  }

  /// Correct a payment (supersede).
  Future<Payment> correctPayment(
    int studentId,
    int paymentId,
    Payment payment,
  ) {
    final payload = Map<String, dynamic>.from(payment.toJson())
      ..remove('id')
      ..remove('student_id');
    return _apiService.update(
      endpoint: '/student/$studentId/payment',
      id: paymentId.toString(),
      data: payload,
    );
  }

  /// Delete a payment (hard delete).
  Future<void> deletePayment(int studentId, int paymentId) {
    return _apiService.delete(
      endpoint: '/student/$studentId/payment',
      id: paymentId.toString(),
    );
  }
}

final paymentsApiServiceProvider = Provider<PaymentsApiService>((ref) {
  final apiService = ref.watch(paymentApiServiceProvider);
  return PaymentsApiService(apiService);
});
