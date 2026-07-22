class PaymentCreate {
  final String paymentType;
  final String payment_category;
  final double amount;
  final String mode;
  final String? txnRef;
  final String? paidOn; // e.g. "2024-01-01T00:00:00+00:00"
  final bool isActive;

  PaymentCreate({
    required this.paymentType,
    required this.amount,
    required this.payment_category,
    required this.mode,
    required this.isActive,
    this.txnRef,
    this.paidOn,
  });

  Map<String, dynamic> toJson() => {
    'payment_type': paymentType,
    'amount': amount,
    'mode': mode,
    'payment_category': payment_category,
    'isActive': isActive,
    if (txnRef != null) 'txn_ref': txnRef,
    if (paidOn != null) 'paid_on': paidOn,
  };
}

class Payment {
  final int? id;
  final int? studentId;
  final String? paymentType;
  final int? amount;
  final String? mode;
  final String? txnRef;
  final String? paidOn;
  final String? status;
  final int? supersededBy;
  final String? payment_category;
  final bool? isActive;

  Payment({
    this.id,
    this.studentId,
    this.paymentType,
    this.amount,
    this.mode,
    this.txnRef,
    this.paidOn,
    this.status,
    this.supersededBy,
    this.isActive,
    this.payment_category,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as int?,
    studentId: json['student_id'] as int?,
    payment_category: json['payment_category'] as String?,
    paymentType: json['payment_type'] as String?,
    amount: json['amount'] as int?,
    mode: json['mode'] as String?,
    txnRef: json['txn_ref'] as String?,
    paidOn: json['paid_on'] as String?,
    status: json['status'] as String?,
    supersededBy: json['superseded_by'] as int?,
    isActive: json['isActive'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'payment_type': paymentType,
    'amount': amount,
    'mode': mode,
    'payment_category': payment_category,
    'isActive': isActive,
    'txn_ref': txnRef,
    'paid_on': paidOn,
    'status': status,
    'superseded_by': supersededBy,
  };

  bool get isSuperseded => status?.toLowerCase() == 'superseded';
}
