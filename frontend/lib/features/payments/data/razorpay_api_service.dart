import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/features/payments/data/checkout_modles.dart';

/// Talks to the online-payment endpoints. Uses Dio directly because these
/// responses are not `Payment` objects, so the generic ApiService<Payment> doesn't fit.
class RazorpayApiService {
  RazorpayApiService(this._dio);

  final Dio _dio;

  Future<CheckoutOptions> startPayment({
    required int studentId,
    int cycles = 1,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/payments/start',
      data: {'student_id': studentId, 'cycles': cycles},
    );
    return CheckoutOptions.fromJson(res.data!);
  }

  Future<VerifyPaymentResult> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/payments/verify',
      data: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );
    return VerifyPaymentResult.fromJson(res.data!);
  }

  Future<OrderStatus> getOrderStatus(String orderId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/payments/order/$orderId/status',
    );
    return OrderStatus.fromJson(res.data!);
  }

  Future<FeeStatus> getFeeStatus(int studentId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/payments/student/$studentId/fee-status',
    );
    return FeeStatus.fromJson(res.data!);
  }
}

final razorpayApiServiceProvider = Provider<RazorpayApiService>(
  (ref) => RazorpayApiService(ref.watch(dioProvider)),
);

/// Turns a thrown error into a short message for the UI.
/// FastAPI errors arrive as {"detail": "..."}.
String paymentErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    return 'Could not reach the server. Please check your connection and try again.';
  }
  return 'Something went wrong. Please try again.';
}
