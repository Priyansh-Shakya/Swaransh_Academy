import 'web_checkout_result.dart';

Future<WebCheckoutResult> openWebCheckout(Map<String, dynamic> options) {
  throw UnsupportedError('Cannot open web checkout on non-web platform.');
}
