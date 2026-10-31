class LoanApplication {
  const LoanApplication({
    required this.id,
    required this.applicationNumber,
    required this.amount,
    required this.tenureMonths,
    required this.status,
    this.emi,
    this.totalPayable,
    this.interestRate,
    this.purpose,
  });

  factory LoanApplication.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;

    return LoanApplication(
      id: json['_id'] as String,
      applicationNumber: json['applicationNumber'] as String,
      amount: json['amount'] as num,
      tenureMonths: (json['tenureMonths'] as num).toInt(),
      status: json['status'] as String,
      emi: json['emi'] as num?,
      totalPayable: json['totalPayable'] as num?,
      interestRate: json['interestRate'] as num?,
      purpose: json['purpose'] as String?,
    );
  }

  final String id;
  final String applicationNumber;
  final num amount;
  final int tenureMonths;

  // submitted | under_review | approved | rejected | disbursed
  final String status;
  final num? emi;
  final num? totalPayable;
  final num? interestRate;
  final String? purpose;

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'disbursed':
        return 'Disbursed';
      default:
        return status;
    }
  }
}
