import 'status_change.dart';

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
    this.statusHistory = const [],
    this.rejectionReason,
    this.createdAt,
  });

  factory LoanApplication.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;
    final history = json['statusHistory'] as List? ?? const [];
    final createdAt = json['createdAt'] as String?;

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
      statusHistory: history.map(StatusChange.fromJson).toList(),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: createdAt == null ? null : DateTime.parse(createdAt).toLocal(),
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
  final List<StatusChange> statusHistory;
  final String? rejectionReason;
  final DateTime? createdAt;

  // When the application first reached [status], taken from the history.
  DateTime? reachedAt(String status) {
    for (final change in statusHistory) {
      if (change.status == status) {
        return change.changedAt;
      }
    }
    return null;
  }
}
