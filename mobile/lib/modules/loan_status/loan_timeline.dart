import '../../core/constants/loan_status.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/widgets/status_timeline.dart';
import '../../data/models/loan_application.dart';

/// Turns an application's status and history into the steps of the timeline:
/// Submitted -> Under Review -> Approved or Rejected -> Disbursed.
List<TimelineStep> buildLoanTimeline(LoanApplication loan) {
  final status = loan.status;
  final isRejected = status == LoanStatus.rejected;

  return [
    TimelineStep(
      title: 'Application Submitted',
      state: TimelineState.done,
      subtitle: _when(loan, LoanStatus.submitted),
    ),
    TimelineStep(
      title: 'Application under Review',
      state: _reviewState(status),
      subtitle: _when(loan, LoanStatus.underReview),
    ),
    _decisionStep(loan),
    // A rejected loan can never be disbursed, so the last step is dropped.
    if (!isRejected)
      TimelineStep(
        title: 'Disbursement',
        state: _disbursementState(status),
        subtitle: _when(loan, LoanStatus.disbursed),
      ),
  ];
}

TimelineState _reviewState(String status) {
  // Submitted and under review both mean "waiting for a decision".
  final waiting =
      status == LoanStatus.submitted || status == LoanStatus.underReview;
  return waiting ? TimelineState.current : TimelineState.done;
}

TimelineStep _decisionStep(LoanApplication loan) {
  switch (loan.status) {
    case LoanStatus.rejected:
      return TimelineStep(
        title: 'Application Rejected',
        state: TimelineState.failed,
        subtitle: loan.rejectionReason ?? _when(loan, LoanStatus.rejected),
      );
    case LoanStatus.approved:
    case LoanStatus.disbursed:
      return TimelineStep(
        title: 'Application Approved',
        state: TimelineState.done,
        subtitle: _when(loan, LoanStatus.approved),
      );
    default:
      return const TimelineStep(
        title: 'Approval Decision',
        state: TimelineState.pending,
      );
  }
}

TimelineState _disbursementState(String status) {
  switch (status) {
    case LoanStatus.disbursed:
      return TimelineState.done;
    case LoanStatus.approved:
      return TimelineState.current;
    default:
      return TimelineState.pending;
  }
}

String? _when(LoanApplication loan, String status) {
  final time = loan.reachedAt(status);
  return time == null ? null : AppFormatters.date(time);
}

/// Headline and explanation shown under the timeline for the current status.
({String title, String message}) describeLoanStatus(LoanApplication loan) {
  switch (loan.status) {
    case LoanStatus.submitted:
      return (
        title: 'Application Submitted',
        message: 'We have received your application and will start reviewing it shortly.',
      );
    case LoanStatus.underReview:
      return (
        title: 'Application Under Review',
        message: "We're carefully reviewing your application to ensure everything is in order. Thank you for your patience.",
      );
    case LoanStatus.approved:
      return (
        title: 'Application Approved',
        message: 'Congratulations! Your loan is approved and will be disbursed soon.',
      );
    case LoanStatus.rejected:
      return (
        title: 'Application Rejected',
        message:
            loan.rejectionReason ??
            'Unfortunately we could not approve this application.',
      );
    default:
      return (
        title: 'Loan Disbursed',
        message: 'Your loan amount has been disbursed. Repay your installments on time to improve your credit score.',
      );
  }
}
