import 'dart:js_interop';
import 'web_checkout_result.dart';

@JS('openRazorpayCheckout')
external JSPromise<JSAny?> _openRazorpayCheckout(JSAny? options);

Future<WebCheckoutResult> openWebCheckout(Map<String, dynamic> options) async {
  try {
    final jsOptions = options.jsify();
    final promise = _openRazorpayCheckout(jsOptions);
    final jsResult = await promise.toDart;
    final dartResult = jsResult?.dartify();

    if (dartResult is Map) {
      final map = Map<String, dynamic>.from(dartResult);
      return WebCheckoutResult(
        status: map['status'] as String? ?? 'error',
        orderId: map['orderId'] as String?,
        paymentId: map['paymentId'] as String?,
        signature: map['signature'] as String?,
        lastError: map['lastError'] as String?,
        message: map['message'] as String?,
      );
    }
    return const WebCheckoutResult(
      status: 'error',
      message: 'Invalid response from checkout bridge',
    );
  } catch (e) {
    return WebCheckoutResult(
      status: 'error',
      message: e.toString(),
    );
  }
}
