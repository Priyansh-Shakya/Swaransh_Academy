import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swaransh_academy/Core/dio_client/dio_client_provider.dart';
import 'package:swaransh_academy/Core/service/api_service.dart';
import 'package:swaransh_academy/features/payments/domain/payment.dart';

final paymentApiServiceProvider = Provider<ApiService<Payment>>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService<Payment>(dio: dio, fromJson: Payment.fromJson);
});

class PaymentNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  PaymentNotifier(this._ref, this.studentId)
    : super(const AsyncValue.loading()) {
    _fetch();
  }

  final Ref _ref;
  final int studentId;

  ApiService<Payment> get _api => _ref.read(paymentApiServiceProvider);
  String get _paymentEndpoint => '/student/$studentId/payment';

  Future<void> _fetch() async {
    state = const AsyncValue.loading();
    try {
      final list = await _api.getAll(
        endpoint: '/student/$studentId/paymentList',
      );
      debugPrint("Payment Notifier , Fetch function: $list");
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _fetch();

  Future<void> add(PaymentCreate body) async {
    await _api.create(endpoint: _paymentEndpoint, data: body.toJson());
    await _fetch(); // refetch so ordering/status come straight from the server
  }

  Future<void> correct(int paymentId, PaymentCreate body) async {
    // PUT supersedes: old row -> status=superseded, a new row is created.
    debugPrint("Correct Payment Notifier Function: ${body.toJson()}");
    await _api.update(
      endpoint: _paymentEndpoint,
      id: paymentId.toString(),
      data: body.toJson(),
    );
    await _fetch();
  }

  Future<void> remove(int paymentId) async {
    await _api.delete(endpoint: _paymentEndpoint, id: paymentId.toString());
    await _fetch();
  }
}

final paymentProvider =
    StateNotifierProvider.family<
      PaymentNotifier,
      AsyncValue<List<Payment>>,
      int
    >((ref, studentId) => PaymentNotifier(ref, studentId));
