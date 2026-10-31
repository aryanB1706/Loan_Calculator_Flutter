import 'credit_score.dart';

class Repayment {
  const Repayment({
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidAt,
  });

  factory Repayment.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;
    final paidAt = json['paidAt'] as String?;

    return Repayment(
      installmentNumber: (json['installmentNumber'] as num).toInt(),
      dueDate: DateTime.parse(json['dueDate'] as String).toLocal(),
      amount: json['amount'] as num,
      status: json['status'] as String,
      paidAt: paidAt == null ? null : DateTime.parse(paidAt).toLocal(),
    );
  }

  final int installmentNumber;
  final DateTime dueDate;
  final num amount;

  // pending | paid | late
  final String status;
  final DateTime? paidAt;

  bool get isPending => status == 'pending';
  bool get isLate => status == 'late';
}

/// Result of paying an installment: the updated row and the new credit score.
class PaymentResult {
  const PaymentResult({required this.repayment, required this.creditScore});

  factory PaymentResult.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;

    return PaymentResult(
      repayment: Repayment.fromJson(json['repayment']),
      creditScore: CreditScore.fromJson(json['creditScore']),
    );
  }

  final Repayment repayment;
  final CreditScore creditScore;
}
