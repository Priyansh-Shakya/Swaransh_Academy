class WebCheckoutResult {
  const WebCheckoutResult({
    required this.status, // 'success' | 'dismissed' | 'error'
    this.orderId,
    this.paymentId,
    this.signature,
    this.lastError,
    this.message,
  });

  final String status;
  final String? orderId;
  final String? paymentId;
  final String? signature;
  final String? lastError;
  final String? message;
}
