/// One entry of a loan's status history: when it moved to a status, and why.
class StatusChange {
  const StatusChange({
    required this.status,
    required this.note,
    required this.changedAt,
  });

  factory StatusChange.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;

    return StatusChange(
      status: json['status'] as String,
      note: json['note'] as String? ?? '',
      changedAt: DateTime.parse(json['changedAt'] as String).toLocal(),
    );
  }

  final String status;
  final String note;
  final DateTime changedAt;
}
