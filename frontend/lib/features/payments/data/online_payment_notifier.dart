import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:swaransh_academy/features/payments/data/checkout_modles.dart';
import 'package:swaransh_academy/features/payments/data/payments_notifier.dart';
import 'package:swaransh_academy/features/payments/data/razorpay_api_service.dart';
import 'package:swaransh_academy/features/payments/data/web_checkout/web_checkout.dart';
import 'package:swaransh_academy/features/profile/data/profile_notifier.dart';

enum PaymentPhase { idle, starting, checkout, verifying, paid, pending, failed }

class PaymentFlowState {
  const PaymentFlowState({
    this.phase = PaymentPhase.idle,
    this.message,
    this.orderId,
    this.feePaidTill,
  });

  final PaymentPhase phase;
  final String? message;
  final String? orderId;
  final DateTime? feePaidTill;

  bool get busy =>
      phase == PaymentPhase.starting ||
      phase == PaymentPhase.checkout ||
      phase == PaymentPhase.verifying;
}

/// Current fee status for the Pay Fees screen (amount, paid-till, next due date).
final feeStatusProvider = FutureProvider.autoDispose.family<FeeStatus, int>((
  ref,
  studentId,
) {
  return ref.watch(razorpayApiServiceProvider).getFeeStatus(studentId);
});

/// Owns the whole online-payment flow for one student:
/// start order -> open checkout -> verify -> (poll if needed).
class OnlinePaymentNotifier
    extends AutoDisposeFamilyAsyncNotifier<PaymentFlowState, int> {
  Razorpay? _razorpay;
  bool _disposed = false;
  String? _orderId;

  RazorpayApiService get _api => ref.read(razorpayApiServiceProvider);

  @override
  Future<PaymentFlowState> build(int studentId) async {
    _disposed = false;
    if (!kIsWeb) {
      _razorpay = Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _onError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    }

    ref.onDispose(() {
      _disposed = true;
      if (!kIsWeb) {
        _razorpay?.clear();
      }
    });
    return const PaymentFlowState();
  }

  void _set(PaymentFlowState next) {
    if (_disposed) return; // never touch state after dispose
    state = AsyncData(next);
  }

  /// Called by the Pay Fees button.
  Future<void> pay({int? amount}) async {
    if (state.valueOrNull?.busy ?? false) return; // ignore double taps

    _set(const PaymentFlowState(phase: PaymentPhase.starting));
    try {
      final options = await _api.startPayment(studentId: arg, amount: amount);
      _orderId = options.orderId;
      _set(
        PaymentFlowState(
          phase: PaymentPhase.checkout,
          orderId: options.orderId,
        ),
      );

      if (kIsWeb) {
        final webResult = await openWebCheckout(options.toRazorpayOptions());
        if (webResult.status == 'success') {
          await _handleSuccess(
            webResult.orderId,
            webResult.paymentId,
            webResult.signature,
          );
        } else if (webResult.status == 'dismissed') {
          var msg =
              'Payment was cancelled or failed. No money is deducted unless the bank confirms it.';
          if (webResult.lastError != null &&
              webResult.lastError!.isNotEmpty) {
            msg += ' (${webResult.lastError})';
          }
          _set(
            PaymentFlowState(
              phase: PaymentPhase.failed,
              orderId: _orderId,
              message: msg,
            ),
          );
        } else {
          _set(
            PaymentFlowState(
              phase: PaymentPhase.failed,
              orderId: _orderId,
              message: webResult.message ?? 'Payment failed on web',
            ),
          );
        }
      } else {
        _razorpay?.open(options.toRazorpayOptions());
      }
    } catch (e) {
      _set(
        PaymentFlowState(
          phase: PaymentPhase.failed,
          message: paymentErrorMessage(e),
        ),
      );
    }
  }

  // ---------------------------------------------------------- checkout callbacks
  Future<void> _handleSuccess(
    String? orderId,
    String? paymentId,
    String? signature,
  ) async {
    final resolvedOrderId = orderId ?? _orderId;
    if (resolvedOrderId == null) {
      _set(
        const PaymentFlowState(
          phase: PaymentPhase.pending,
          message:
              "We're confirming your payment. Your fee status will update shortly.",
        ),
      );
      return;
    }

    _set(PaymentFlowState(
      phase: PaymentPhase.verifying,
      orderId: resolvedOrderId,
    ));

    if (paymentId != null && signature != null) {
      try {
        final result = await _api.verifyPayment(
          orderId: resolvedOrderId,
          paymentId: paymentId,
          signature: signature,
        );
        if (result.isPaid) {
          _setPaid(resolvedOrderId, result.feePaidTill);
          return;
        }
      } catch (_) {
        // Network hiccup or not captured yet: fall back to polling below.
      }
    }
    await _pollUntilPaid(resolvedOrderId);
  }

  Future<void> _onSuccess(PaymentSuccessResponse r) async {
    await _handleSuccess(r.orderId, r.paymentId, r.signature);
  }

  void _onError(PaymentFailureResponse r) {
    // Fires on failure AND when the user closes checkout.
    final String errorDetails = r.message ?? '';
    final isCancelled = r.code == Razorpay.PAYMENT_CANCELLED ||
        errorDetails.toLowerCase().contains('cancelled') ||
        errorDetails.toLowerCase().contains('canceled');

    final String message = isCancelled
        ? 'Payment was cancelled. No money is deducted unless the bank confirms it.'
        : (errorDetails.isNotEmpty
            ? 'Payment failed (${r.code}): $errorDetails'
            : 'Payment failed or was cancelled. Please try again.');

    _set(
      PaymentFlowState(
        phase: PaymentPhase.failed,
        orderId: _orderId,
        message: message,
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse r) {}

  // ---------------------------------------------------------- helpers
  Future<void> _pollUntilPaid(String orderId) async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_disposed) return;
      try {
        final status = await _api.getOrderStatus(orderId);
        if (status.isPaid) {
          if (status.lastError != null) {
            _set(
              PaymentFlowState(
                phase: PaymentPhase.failed,
                orderId: orderId,
                message: 'Payment failed: ${status.lastError}',
              ),
            );
            return;
          }
          _setPaid(orderId, status.feePaidTill);
          return;
        }
      } catch (_) {
        // keep trying
      }
    }
    _set(
      PaymentFlowState(
        phase: PaymentPhase.pending,
        orderId: orderId,
        message:
            "We're confirming your payment. Your fee status will update shortly.",
      ),
    );
  }

  void _setPaid(String orderId, DateTime? feePaidTill) {
    _set(
      PaymentFlowState(
        phase: PaymentPhase.paid,
        orderId: orderId,
        feePaidTill: feePaidTill,
      ),
    );
    if (!_disposed) {
      ref.invalidate(feeStatusProvider(arg));
      ref.invalidate(paymentProvider(arg));
      ref.invalidate(profileProvider);
    }
  }
}

final onlinePaymentProvider = AsyncNotifierProvider.autoDispose
    .family<OnlinePaymentNotifier, PaymentFlowState, int>(
      OnlinePaymentNotifier.new,
    );
