class Payment {
  const Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.feeType,
    required this.paymentDate,
    required this.status,
    this.modeOfPayment,
    this.receiptNo,
    this.notes,
    this.superceededBy,
  });

  final int id;
  final int studentId;
  final double amount;
  final String feeType;
  final String paymentDate;
  final String status;
  final String? modeOfPayment;
  final String? receiptNo;
  final String? notes;
  final int? superceededBy;

  Payment copyWith({
    double? amount,
    String? feeType,
    String? paymentDate,
    String? status,
    String? modeOfPayment,
    String? receiptNo,
    String? notes,
    int? superceededBy,
  }) {
    return Payment(
      id: id,
      studentId: studentId,
      amount: amount ?? this.amount,
      feeType: feeType ?? this.feeType,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      modeOfPayment: modeOfPayment ?? this.modeOfPayment,
      receiptNo: receiptNo ?? this.receiptNo,
      notes: notes ?? this.notes,
      superceededBy: superceededBy ?? this.superceededBy,
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as int,
    studentId: json['student_id'] as int,
    amount: (json['amount'] as num).toDouble(),
    feeType: json['fee_type'] as String,
    paymentDate: json['payment_date'] as String,
    status: json['status'] as String,
    modeOfPayment: json['mode_of_payment'] as String?,
    receiptNo: json['receipt_no'] as String?,
    notes: json['notes'] as String?,
    superceededBy: json['superceeded_by'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'amount': amount,
    'fee_type': feeType,
    'payment_date': paymentDate,
    'status': status,
    'mode_of_payment': modeOfPayment,
    'receipt_no': receiptNo,
    'notes': notes,
    'superceeded_by': superceededBy,
  };
}
