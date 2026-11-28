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
    required this.coversFrom,
    required this.coversTill,
    required this.cycleLabel,
    required this.isPartial,
  });

  final String keyId;
  final String orderId;
  final int amount; // paise
  final String currency;
  final String name;
  final String description;
  final CheckoutPrefill prefill;
  final DateTime coversFrom;
  final DateTime coversTill;
  final String cycleLabel;
  final bool isPartial;

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
        coversFrom: DateTime.parse(json['covers_from'] as String),
        coversTill: DateTime.parse(json['covers_till'] as String),
        cycleLabel: json['cycle_label'] as String? ?? '',
        isPartial: json['is_partial'] as bool? ?? false,
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
    this.lastError,
  });

  final String orderId;
  final String status; // 'created' | 'paid'
  final DateTime? feePaidTill;
  final String? lastError;

  bool get isPaid => status == 'paid';

  factory OrderStatus.fromJson(Map<String, dynamic> json) => OrderStatus(
    orderId: json['razorpay_order_id'] as String,
    status: json['status'] as String,
    feePaidTill: _date(json['fee_paid_till']),
    lastError: json['last_error'] as String?,
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
    required this.canPay,
    required this.cycleStart,
    required this.cycleEnd,
    required this.cycleLabel,
    required this.cycleFee,
    required this.cyclePaid,
    required this.cycleBalance,
    required this.allowPartialPayment,
    this.partialPaymentAmount,
    this.partPaymentAvailable = false,
    this.hasUnlinkedPayments = false,
    this.cannotPayReason,
    this.feePaidTill,
  });

  final int studentId;
  final String feeType;
  final int feeAmount; // rupees per cycle
  final DateTime? feePaidTill;
  final DateTime nextDueDate;
  final bool isDue;
  final bool canPay;
  final String? cannotPayReason;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final String cycleLabel;
  final int cycleFee;
  final int cyclePaid;
  final int cycleBalance;
  final bool allowPartialPayment;
  final int? partialPaymentAmount;
  final bool partPaymentAvailable;
  final bool hasUnlinkedPayments;

  factory FeeStatus.fromJson(Map<String, dynamic> json) => FeeStatus(
    studentId: (json['student_id'] as num).toInt(),
    feeType: json['fee_type'] as String,
    feeAmount: (json['fee_amount'] as num).toInt(),
    feePaidTill: _date(json['fee_paid_till']),
    nextDueDate: DateTime.parse(json['next_due_date'] as String),
    isDue: json['is_due'] as bool? ?? true,
    canPay: json['can_pay'] as bool? ?? true,
    cannotPayReason: json['cannot_pay_reason'] as String?,
    cycleStart: DateTime.parse(json['cycle_start'] as String),
    cycleEnd: DateTime.parse(json['cycle_end'] as String),
    cycleLabel: json['cycle_label'] as String? ?? '',
    cycleFee: (json['cycle_fee'] as num).toInt(),
    cyclePaid: (json['cycle_paid'] as num).toInt(),
    cycleBalance: (json['cycle_balance'] as num).toInt(),
    allowPartialPayment: json['allow_partial_payment'] as bool? ?? false,
    partialPaymentAmount: (json['partial_payment_amount'] as num?)?.toInt(),
    partPaymentAvailable: json['part_payment_available'] as bool? ?? false,
    hasUnlinkedPayments: json['has_unlinked_payments'] as bool? ?? false,
  );
}
