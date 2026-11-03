/// Models for the online (Razorpay) payment flow. Field names mirror the backend Pydantic models.
library;

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

class CheckoutPrefill {
  const CheckoutPrefill({this.name, this.contact, this.email});

  final String? name;
  final String? contact;
  final String? email;

  factory CheckoutPrefill.fromJson(Map<String, dynamic> json) =>
      CheckoutPrefill(
        name: json['name'] as String?,
        contact: json['contact'] as String?,
        email: json['email'] as String?,
      );

  /// Empty values are left out on purpose: empty prefill strings can upset checkout.
  Map<String, dynamic> toRazorpayJson() {
    final map = <String, dynamic>{};
    final n = name, c = contact, e = email;
    if (n != null && n.isNotEmpty) map['name'] = n;
    if (c != null && c.isNotEmpty) map['contact'] = c;
    if (e != null && e.isNotEmpty) map['email'] = e;
    return map;
  }
}

/// Response of POST /payments/start.
class CheckoutOptions {
  const CheckoutOptions({
    required this.keyId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.name,
    required this.description,
    required this.prefill,
    required this.cycles,
    required this.coversFrom,
    required this.coversTill,
  });

  final String keyId;
  final String orderId;
  final int amount; // paise
  final String currency;
  final String name;
  final String description;
  final CheckoutPrefill prefill;
  final int cycles;
  final DateTime coversFrom;
  final DateTime coversTill;

  factory CheckoutOptions.fromJson(Map<String, dynamic> json) =>
      CheckoutOptions(
        keyId: json['key_id'] as String,
        orderId: json['order_id'] as String,
        amount: (json['amount'] as num).toInt(),
        currency: (json['currency'] as String?) ?? 'INR',
        name: json['name'] as String,
        description: json['description'] as String,
        prefill: CheckoutPrefill.fromJson(
          json['prefill'] as Map<String, dynamic>,
        ),
        cycles: (json['cycles'] as num).toInt(),
        coversFrom: DateTime.parse(json['covers_from'] as String),
        coversTill: DateTime.parse(json['covers_till'] as String),
      );

  /// The options map handed to razorpay.open(...).
  Map<String, dynamic> toRazorpayOptions() => {
    'key': keyId,
    'order_id': orderId,
    'amount': amount,
    'currency': currency,
    'name': name,
    'description': description,
    'prefill': prefill.toRazorpayJson(),
    'theme': {'color': '#6C3CE1'},
    'retry': {'enabled': true, 'max_count': 2},
  };
}

/// Response of POST /payments/verify.
class VerifyPaymentResult {
  const VerifyPaymentResult({
    required this.status,
    this.paymentId,
    this.feePaidTill,
  });

  final String status; // 'paid' | 'pending'
  final int? paymentId;
  final DateTime? feePaidTill;

  bool get isPaid => status == 'paid';

  factory VerifyPaymentResult.fromJson(Map<String, dynamic> json) =>
      VerifyPaymentResult(
        status: json['status'] as String,
        paymentId: (json['payment_id'] as num?)?.toInt(),
        feePaidTill: _date(json['fee_paid_till']),
      );
}

/// Response of GET /payments/order/{id}/status.
class OrderStatus {
  const OrderStatus({
    required this.orderId,
    required this.status,
    this.feePaidTill,
  });

  final String orderId;
  final String status; // 'created' | 'paid'
  final DateTime? feePaidTill;

  bool get isPaid => status == 'paid';

  factory OrderStatus.fromJson(Map<String, dynamic> json) => OrderStatus(
    orderId: json['razorpay_order_id'] as String,
    status: json['status'] as String,
    feePaidTill: _date(json['fee_paid_till']),
  );
}

/// Response of GET /payments/student/{id}/fee-status.
class FeeStatus {
  const FeeStatus({
    required this.studentId,
    required this.feeType,
    required this.feeAmount,
    required this.nextDueDate,
    required this.isDue,
    this.feePaidTill,
  });

  final int studentId;
  final String feeType;
  final int feeAmount; // rupees per cycle
  final DateTime? feePaidTill;
  final DateTime nextDueDate;
  final bool isDue;

  factory FeeStatus.fromJson(Map<String, dynamic> json) => FeeStatus(
    studentId: (json['student_id'] as num).toInt(),
    feeType: json['fee_type'] as String,
    feeAmount: (json['fee_amount'] as num).toInt(),
    feePaidTill: _date(json['fee_paid_till']),
    nextDueDate: DateTime.parse(json['next_due_date'] as String),
    isDue: json['is_due'] as bool,
  );
}
