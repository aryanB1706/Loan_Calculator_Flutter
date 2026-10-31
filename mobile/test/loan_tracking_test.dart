import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:loan_app/core/network/api_client.dart';
import 'package:loan_app/core/theme/app_theme.dart';
import 'package:loan_app/core/widgets/status_timeline.dart';
import 'package:loan_app/data/models/credit_score.dart';
import 'package:loan_app/data/models/loan_application.dart';
import 'package:loan_app/data/models/loan_page.dart';
import 'package:loan_app/data/models/repayment.dart';
import 'package:loan_app/data/models/status_change.dart';
import 'package:loan_app/data/repositories/loan_repository.dart';
import 'package:loan_app/modules/applications/applications_controller.dart';
import 'package:loan_app/modules/loan_status/loan_status_controller.dart';
import 'package:loan_app/modules/loan_status/loan_status_view.dart';
import 'package:loan_app/modules/loan_status/loan_timeline.dart';

class _NoApi implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

LoanApplication _loan(
  String status, {
  String id = 'l1',
  String? rejectionReason,
  List<StatusChange> history = const [],
}) {
  return LoanApplication(
    id: id,
    applicationNumber: 'LN-$id',
    amount: 50000,
    tenureMonths: 3,
    status: status,
    statusHistory: history,
    rejectionReason: rejectionReason,
  );
}

Repayment _installment(int number, {String status = 'pending'}) {
  return Repayment(
    installmentNumber: number,
    dueDate: DateTime(2026, 12, number),
    amount: 17000,
    status: status,
  );
}

class _FakeLoans extends LoanRepository {
  _FakeLoans({this.loan, this.schedule = const [], this.pages = const []})
    : super(_NoApi());

  LoanApplication? loan;
  List<Repayment> schedule;
  final List<LoanPage> pages;
  final List<int> requestedPages = [];

  @override
  Future<LoanApplication> getApplication(String id) async => loan!;

  @override
  Future<List<Repayment>> repayments(String loanId) async => schedule;

  @override
  Future<PaymentResult> payInstallment(String loanId, int number) async {
    final paid = _installment(number, status: 'paid');
    return PaymentResult(
      repayment: paid,
      creditScore: const CreditScore(score: 660, band: 'fair'),
    );
  }

  @override
  Future<LoanPage> listApplications({int page = 1, int limit = 10}) async {
    requestedPages.add(page);
    return pages[page - 1];
  }
}

List<TimelineState> _states(LoanApplication loan) {
  return buildLoanTimeline(loan).map((step) => step.state).toList();
}

void main() {
  tearDown(Get.reset);

  group('timeline', () {
    test('submitted and under review both wait for review', () {
      const waiting = [
        TimelineState.done,
        TimelineState.current,
        TimelineState.pending,
        TimelineState.pending,
      ];

      expect(_states(_loan('submitted')), waiting);
      expect(_states(_loan('under_review')), waiting);
    });

    test('approved waits for disbursement', () {
      expect(_states(_loan('approved')), [
        TimelineState.done,
        TimelineState.done,
        TimelineState.done,
        TimelineState.current,
      ]);
    });

    test(
      'rejected fails the decision, shows the reason and drops disbursement',
      () {
        final steps = buildLoanTimeline(
          _loan('rejected', rejectionReason: 'Low credit score'),
        );

        expect(steps, hasLength(3));
        expect(steps.last.state, TimelineState.failed);
        expect(steps.last.title, 'Application Rejected');
        expect(steps.last.subtitle, 'Low credit score');
      },
    );

    test('disbursed completes every step', () {
      expect(_states(_loan('disbursed')), everyElement(TimelineState.done));
    });

    test('steps show the date they were reached', () {
      final steps = buildLoanTimeline(
        _loan(
          'under_review',
          history: [
            StatusChange(
              status: 'submitted',
              note: '',
              changedAt: DateTime(2026, 10, 31),
            ),
          ],
        ),
      );

      expect(steps.first.subtitle, '31 Oct 2026');
      expect(steps[1].subtitle, isNull);
    });
  });

  testWidgets('status screen renders the timeline at phone size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(786, 1844);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    Get.put(
      LoanStatusController(
        _FakeLoans(loan: _loan('under_review')),
        _loan('submitted'),
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const LoanStatusView()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Application under Review'), findsWidgets);
    expect(find.textContaining('#LN-l1', findRichText: true), findsOneWidget);
    expect(find.text('Pay ₹17,000.00'), findsNothing);
  });

  group('repayments', () {
    test(
      'a disbursed loan loads its schedule and the next installment',
      () async {
        final repo = _FakeLoans(
          loan: _loan('disbursed'),
          schedule: [
            _installment(1, status: 'paid'),
            _installment(2),
            _installment(3),
          ],
        );
        final controller = LoanStatusController(repo, _loan('disbursed'));

        await controller.reload();

        expect(controller.repayments, hasLength(3));
        expect(controller.nextInstallment?.installmentNumber, 2);
      },
    );

    test('a loan that is not disbursed does not load repayments', () async {
      final repo = _FakeLoans(
        loan: _loan('approved'),
        schedule: [_installment(1)],
      );
      final controller = LoanStatusController(repo, _loan('approved'));

      await controller.reload();

      expect(controller.repayments, isEmpty);
    });

    testWidgets('paying marks the installment paid and moves to the next', (
      tester,
    ) async {
      final repo = _FakeLoans(
        loan: _loan('disbursed'),
        schedule: [_installment(1), _installment(2)],
      );
      final controller = LoanStatusController(repo, _loan('disbursed'));
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
      await controller.reload();

      await controller.payNextInstallment();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(controller.repayments.first.status, 'paid');
      expect(controller.nextInstallment?.installmentNumber, 2);
      expect(controller.isPaying.value, isFalse);
    });
  });

  group('applications list', () {
    LoanPage page(int number, int total, List<LoanApplication> items) =>
        LoanPage(applications: items, page: number, totalPages: total);

    test(
      'loads page one, then appends the next page and stops at the end',
      () async {
        final repo = _FakeLoans(
          pages: [
            page(1, 2, [_loan('submitted', id: 'a')]),
            page(2, 2, [_loan('rejected', id: 'b')]),
          ],
        );
        final controller = ApplicationsController(repo);

        await controller.reload();
        expect(controller.applications, hasLength(1));

        await controller.loadMore();
        expect(controller.applications.map((a) => a.id), ['a', 'b']);

        await controller.loadMore();
        expect(repo.requestedPages, [1, 2]);
      },
    );

    test('reload starts again from page one', () async {
      final repo = _FakeLoans(
        pages: [
          page(1, 1, [_loan('submitted', id: 'a')]),
        ],
      );
      final controller = ApplicationsController(repo);

      await controller.reload();
      await controller.reload();

      expect(controller.applications, hasLength(1));
      expect(repo.requestedPages, [1, 1]);
    });
  });
}
