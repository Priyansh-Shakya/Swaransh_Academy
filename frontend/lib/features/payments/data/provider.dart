import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/payments/domain/payment.dart';

final paymentApiServiceProvider = Provider<ApiService<Payment>>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService<Payment>(dio: dio, fromJson: Payment.fromJson);
});
