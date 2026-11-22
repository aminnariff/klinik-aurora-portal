import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/config/theme.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_checkout_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/service_branch/service_branch_available_response.dart' as sba;
import 'package:klinik_aurora_portal/views/appointment/appointment_checkout_dialog.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:provider/provider.dart';

// ── Fixtures ─────────────────────────────────────────────────────────────

const _detailMilestone = CheckoutMilestoneRule(
  key: 'detail_scan',
  label: 'W18–24 Detail Anomaly Scan',
  bonusPoints: 100,
  minWeek: 18,
  maxWeek: 24,
);

/// The windows the checkout preview sends (from the clinic's tagged services).
const _serverMilestones = [
  CheckoutMilestoneRule(key: 'nt_scan', label: 'W11–13 NT & 1st Trimester Scan', bonusPoints: 50, minWeek: 11, maxWeek: 13),
  _detailMilestone,
  CheckoutMilestoneRule(key: 'scan_4d5d', label: 'W26–32 4D/5D/HD Live Scan', bonusPoints: 100, minWeek: 26, maxWeek: 32),
  CheckoutMilestoneRule(key: 'growth_scan', label: 'W33–36 Growth & Position Scan', bonusPoints: 50, minWeek: 33, maxWeek: 36),
];

CheckoutPreviewData _preview({
  double basePrice = 150.0,
  double bookingFeePaid = 30.0,
  int currentPoints = 200,
  String serviceName = 'Detail Anomaly Scan',
  CheckoutMilestoneRule? milestone = _detailMilestone,
}) {
  return CheckoutPreviewData(
    appointmentId: 'appt-123',
    userId: 'usr-456',
    patientName: 'Siti Nurhaliza',
    patientPhone: '0123456789',
    branchId: 'br-1',
    branchName: 'Bangi Central',
    doctorName: 'Dr. Sarah',
    serviceName: serviceName,
    basePrice: basePrice,
    bookingFeePaid: bookingFeePaid,
    expectedBalance: basePrice - bookingFeePaid,
    currentPoints: currentPoints,
    gestationalWeek: 20,
    detectedMilestone: milestone,
    milestones: _serverMilestones,
    suggestedAddOns: const [],
  );
}

/// Services offered at branch `br-1`, in the order the API returns them.
final _branchServices = <sba.Data>[
  sba.Data(serviceBranchId: 'sb-growth', serviceName: 'Growth Scan'),
  sba.Data(serviceBranchId: 'sb-nt', serviceName: 'NT Dating Scan'),
  sba.Data(serviceBranchId: 'sb-detail', serviceName: 'Detail Anomaly Scan', dueDateToggle: 1),
  sba.Data(serviceBranchId: 'sb-4d', serviceName: '4D/5D HD Live Scan'),
];

/// Records what the dialogs send to the API and answers with canned data.
class _FakeApi {
  _FakeApi(this.preview);

  final CheckoutPreviewData preview;
  final List<Map<String, Object?>> submissions = [];
  final List<String?> serviceRequests = [];
  final List<String> babyTrackerRequests = [];

  /// The patient's Baby Tracker EDD and birth, as admin/user-management/baby-tracker answers.
  String? babyTrackerEdd;
  String? babyTrackerBirth;

  Future<ApiResponse<dynamic>> loadBabyTracker(BuildContext context, String userId) async {
    babyTrackerRequests.add(userId);
    return ApiResponse(
      code: 200,
      data: {
        'message': 'ok',
        'data': {
          'profile': babyTrackerEdd == null
              ? null
              : {'eddDate': babyTrackerEdd, 'babyCount': 1, 'birthDate': babyTrackerBirth},
        },
      },
    );
  }

  Future<ApiResponse<CheckoutPreviewData>> loadPreview(BuildContext context, String appointmentId) async {
    return ApiResponse(code: 200, data: preview);
  }

  Future<ApiResponse<CheckoutResultData>> submit(
    BuildContext context,
    String appointmentId, {
    double? totalSpend,
    required double basePrice,
    required double bookingFeePaid,
    required List<CheckoutAddOnItem> extraItems,
    required double netCollected,
    required String paymentMethod,
    bool awardPoints = true,
    required int basePoints,
    required int milestoneBonusPoints,
    String? milestoneKey,
    String? milestoneName,
    String? adminNotes,
  }) async {
    submissions.add({
      'totalSpend': totalSpend,
      'basePrice': basePrice,
      'bookingFeePaid': bookingFeePaid,
      'netCollected': netCollected,
      'basePoints': basePoints,
      'milestoneBonusPoints': milestoneBonusPoints,
    });
    return ApiResponse(
      code: 200,
      data: CheckoutResultData(
        appointmentId: appointmentId,
        patientName: preview.patientName,
        serviceName: preview.serviceName,
        grossTotal: totalSpend ?? basePrice,
        bookingFeePaid: bookingFeePaid,
        netCollected: netCollected,
        paymentMethod: paymentMethod,
        pointsAwarded: basePoints,
        basePoints: basePoints,
        milestoneBonusPoints: milestoneBonusPoints,
        newTotalPoints: preview.currentPoints + basePoints,
        whatsappReceipt: '',
      ),
    );
  }

  Future<ApiResponse<sba.ServiceBranchAvailableResponse>> loadServices(
    BuildContext context, {
    String? branchId,
  }) async {
    serviceRequests.add(branchId);
    return ApiResponse(
      code: 200,
      data: sba.ServiceBranchAvailableResponse(data: List.of(_branchServices)),
    );
  }
}

// ── Harness ──────────────────────────────────────────────────────────────

class _Harness {
  _Harness(this.api);

  final _FakeApi api;
  bool? checkoutResult;
  bool checkoutClosed = false;
  int onCompletedCalls = 0;
}

/// Pumps the app shell and opens the checkout dialog the same way
/// [AppointmentCheckoutDialog.show] does, but with the fake API wired in.
Future<_Harness> _openCheckout(WidgetTester tester, CheckoutPreviewData preview) async {
  tester.view.physicalSize = const Size(1728, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final harness = _Harness(_FakeApi(preview));
  final branches = BranchController()
    ..branchAllResponse = ApiResponse(
      code: 200,
      data: branch_model.BranchAllResponse(
        data: [branch_model.Data(branchId: 'br-1', branchName: 'Bangi Central')],
      ),
    );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider.value(value: branches),
        ChangeNotifierProvider(create: (_) => ServiceBranchController()),
        ChangeNotifierProvider(create: (_) => ServiceController()),
        ChangeNotifierProvider(create: (_) => ServiceBranchAvailableDtController()),
        ChangeNotifierProvider(create: (_) => AppointmentController()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(1728, 829),
        builder: (context, _) => MaterialApp(
          theme: buildLightTheme(context),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  harness.checkoutResult = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AppointmentCheckoutDialog(
                      appointmentId: preview.appointmentId,
                      onCompleted: () => harness.onCompletedCalls++,
                      loadPreview: harness.api.loadPreview,
                      submitCheckout: harness.api.submit,
                      loadRebookingServices: harness.api.loadServices,
                      loadBabyTrackerProfile: harness.api.loadBabyTracker,
                    ),
                  );
                  harness.checkoutClosed = true;
                },
                child: const Text('open checkout'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open checkout'));
  await tester.pumpAndSettle();
  expect(find.text('Complete Visit & Award Points'), findsOneWidget);
  return harness;
}

/// The value text of a receipt row (label on the left, amount on the right).
String _receiptAmount(WidgetTester tester, String label) {
  final row = find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
  final texts = tester.widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)));
  return texts.last.data!;
}

/// The amount-paid-at-counter field (the form's first text field).
Finder get _counterPaidField => find.byType(TextField).first;

Future<void> _setCounterPaid(WidgetTester tester, String value) async {
  await tester.enterText(_counterPaidField, value);
  await tester.pump();
}

String _counterPaidText(WidgetTester tester) => tester.widget<TextField>(_counterPaidField).controller!.text;

Future<void> _completeCheckout(WidgetTester tester) async {
  final button = find.textContaining('Complete & Award');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.text('Appointment Completed!'), findsOneWidget);
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

const _followUpLabel = 'Susulan / Ulang Servis Sama (1–2 Minggu)';

/// The default test font draws every glyph as a full square, which makes
/// text roughly twice as wide as in the app and reports overflows that never
/// happen for real. Load the app's own font so layout matches production.
Future<void> _loadAppFont() async {
  final loader = FontLoader('Figtree');
  for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
    loader.addFont(rootBundle.load('assets/typography/figtree/Figtree-$weight.ttf'));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadAppFont);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await Storage.init();
  });

  // ── Pure rules ───────────────────────────────────────────────────────────

  group('nextMilestoneAfter: scan chain NT/dating → Detail → 4D/5D → Growth', () {
    // Labels as the checkout preview sends them (weeks from the clinic's services).
    const serverMilestones = [
      CheckoutMilestoneRule(key: 'nt_scan', label: 'W11–13 NT & 1st Trimester Scan', bonusPoints: 50, minWeek: 11, maxWeek: 13),
      CheckoutMilestoneRule(key: 'detail_scan', label: 'W18–24 Detail Anomaly Scan', bonusPoints: 100, minWeek: 18, maxWeek: 24),
      CheckoutMilestoneRule(key: 'scan_4d5d', label: 'W26–32 4D/5D/HD Live Scan', bonusPoints: 100, minWeek: 26, maxWeek: 32),
      CheckoutMilestoneRule(key: 'growth_scan', label: 'W33–36 Growth & Position Scan', bonusPoints: 50, minWeek: 33, maxWeek: 36),
    ];

    final chain = <String?, (String title, String? keyword)>{
      'nt_scan': ('W18–24 Detail Anomaly Scan', 'detail'),
      'detail_scan': ('W26–32 4D/5D/HD Live Scan', '4d'),
      'scan_4d5d': ('W33–36 Growth & Position Scan', 'growth'),
      'growth_scan': ('Postnatal & Newborn Care Visit', null),
      null: ('Next Follow-Up Appointment', null),
      'postnatal': ('Next Follow-Up Appointment', null),
    };

    chain.forEach((completed, expected) {
      test('after ${completed ?? 'no milestone'} → ${expected.$1}', () {
        final next = nextMilestoneAfter(completed, milestones: serverMilestones);
        expect(next.title, expected.$1);
        expect(next.serviceKeyword, expected.$2);
      });
    });

    test('titles follow the windows the server sends (e.g. twins)', () {
      const twin = [
        CheckoutMilestoneRule(key: 'scan_4d5d', label: 'W20–28 4D/5D/HD Live Scan', bonusPoints: 100, minWeek: 20, maxWeek: 28),
      ];
      expect(nextMilestoneAfter('detail_scan', milestones: twin).title, 'W20–28 4D/5D/HD Live Scan');
    });

    test('without server milestones the title has no weeks', () {
      expect(nextMilestoneAfter('nt_scan').title, 'Detail Anomaly Scan');
    });

    test('each scan keyword selects exactly the next scan from the branch menu', () {
      final menu = [for (final s in _branchServices) DropdownAttribute(s.serviceBranchId!, s.serviceName!)]
        ..sort((a, b) => a.name.compareTo(b.name));

      String? pick(String key) => matchServiceByKeyword(menu, nextMilestoneAfter(key).serviceKeyword)?.name;

      expect(pick('nt_scan'), 'Detail Anomaly Scan');
      expect(pick('detail_scan'), '4D/5D HD Live Scan');
      expect(pick('scan_4d5d'), 'Growth Scan');
    });
  });

  group('matchServiceByKeyword', () {
    final menu = [
      DropdownAttribute('sb-4d', '4D/5D HD Live Scan'),
      DropdownAttribute('sb-detail', 'Detail Anomaly Scan'),
      DropdownAttribute('sb-growth', 'Growth Scan'),
    ];

    test('matches a substring case-insensitively', () {
      expect(matchServiceByKeyword(menu, '4D')?.key, 'sb-4d');
      expect(matchServiceByKeyword(menu, 'DETAIL')?.key, 'sb-detail');
    });

    test('matches the full service name used by the same-service follow-up', () {
      expect(matchServiceByKeyword(menu, 'Detail Anomaly Scan')?.key, 'sb-detail');
    });

    test('returns null for a missing, empty or unmatched keyword', () {
      expect(matchServiceByKeyword(menu, null), isNull);
      expect(matchServiceByKeyword(menu, ''), isNull);
      expect(matchServiceByKeyword(menu, 'postnatal'), isNull);
    });
  });

  // ── Counter checkout math ──────────────────────────────────────────────

  group('Counter checkout math', () {
    testWidgets('expected counter balance = service price − online deposit, pre-filled', (tester) async {
      final h = await _openCheckout(tester, _preview(basePrice: 150, bookingFeePaid: 30));

      expect(_receiptAmount(tester, 'Service Price'), 'RM 150.00');
      expect(_receiptAmount(tester, 'Deposit (Paid Online / Booked)'), '-RM 30.00');
      expect(_receiptAmount(tester, 'Expected Counter Balance'), 'RM 120.00');
      expect(find.text('Amount Paid at Counter Today (RM)'), findsOneWidget);
      expect(_counterPaidText(tester), '120.00');
      expect(_receiptAmount(tester, 'Total Patient Spend Today'), 'RM 150.00');

      await _completeCheckout(tester);
      final sent = h.api.submissions.single;
      expect(sent['basePrice'], 150.0);
      expect(sent['bookingFeePaid'], 30.0);
      expect(sent['netCollected'], 120.0);
      expect(sent['totalSpend'], 150.0);
    });

    testWidgets('paying more at the counter shows the extra as add-ons and raises the spend', (tester) async {
      final h = await _openCheckout(tester, _preview(basePrice: 150, bookingFeePaid: 30));

      await _setCounterPaid(tester, '205');
      expect(_receiptAmount(tester, 'Extra Add-ons / Items'), '+RM 85.00');
      expect(_receiptAmount(tester, 'Total Patient Spend Today'), 'RM 235.00');

      await _completeCheckout(tester);
      expect(h.api.submissions.single['netCollected'], 205.0);
      expect(h.api.submissions.single['totalSpend'], 235.0);
      expect(_receiptAmount(tester, 'Extra Add-ons'), '+RM 85.00');
      expect(_receiptAmount(tester, 'Total Spend'), 'RM 235.00');
    });

    testWidgets('paying less at the counter shows a discount', (tester) async {
      await _openCheckout(tester, _preview(basePrice: 150, bookingFeePaid: 30));

      await _setCounterPaid(tester, '100');
      expect(_receiptAmount(tester, 'Discount / Adjustment'), '-RM 20.00');
      expect(_receiptAmount(tester, 'Total Patient Spend Today'), 'RM 130.00');
    });

    testWidgets('without a deposit the field is pre-filled with the service price', (tester) async {
      await _openCheckout(tester, _preview(basePrice: 80, bookingFeePaid: 0));

      expect(find.text('Total Amount Paid (RM)'), findsOneWidget);
      expect(find.text('Deposit (Paid Online / Booked)'), findsNothing);
      expect(_counterPaidText(tester), '80.00');
    });

    testWidgets('the balance never goes negative when the deposit exceeds the price', (tester) async {
      await _openCheckout(tester, _preview(basePrice: 20, bookingFeePaid: 30));

      expect(_receiptAmount(tester, 'Expected Counter Balance'), 'RM 0.00');
      expect(_counterPaidText(tester), '0.00');
      // Points still count the deposit the patient paid: floor(30 / 10).
      expect(find.text('Complete & Award 3 Pts'), findsOneWidget);
    });
  });

  group('Cashier points: floor(total spend / 10), deposit included', () {
    // Points are earned on the patient's whole spend for the visit: the online
    // deposit plus what the cashier collects (fix 61b0dab, "award points on
    // full gross spend including deposit").
    final cases = <(double price, double deposit, int points)>[
      (150, 0, 15), //  floor(150 / 10)
      (159.99, 0, 15), //  rounds down, never up
      (9.99, 0, 0), //  under RM 10 earns nothing
      (10, 0, 1), //  exactly RM 10
      (150, 30, 15), //  deposit counts: floor((120 + 30) / 10)
      (215, 30, 21), //  floor(215 / 10), not 21.5
    ];

    for (final (price, deposit, points) in cases) {
      testWidgets('price RM $price, deposit RM $deposit → $points pts', (tester) async {
        final h = await _openCheckout(tester, _preview(basePrice: price, bookingFeePaid: deposit, currentPoints: 200));

        expect(find.text('Complete & Award $points Pts'), findsOneWidget);
        expect(find.text('+$points Aurora Points'), findsOneWidget);
        expect(find.textContaining('New balance: ${200 + points} pts'), findsOneWidget);

        await _completeCheckout(tester);
        expect(h.api.submissions.single['basePoints'], points);
        expect(h.api.submissions.single['milestoneBonusPoints'], 0);
      });
    }

    testWidgets('extra items paid at the counter earn points too', (tester) async {
      final h = await _openCheckout(tester, _preview(basePrice: 100, bookingFeePaid: 0));

      expect(find.text('Complete & Award 10 Pts'), findsOneWidget);
      await _setCounterPaid(tester, '160');
      expect(find.text('Complete & Award 16 Pts'), findsOneWidget);

      await _completeCheckout(tester);
      expect(h.api.submissions.single['basePoints'], 16);
    });
  });

  // ── Dual re-booking after checkout ─────────────────────────────────────

  group('Dual re-booking buttons on the receipt', () {
    // Titles come from the preview's server milestones (_serverMilestones).
    final scanChain = <String, (String title, String service)>{
      'nt_scan': ('W18–24 Detail Anomaly Scan', 'Detail Anomaly Scan'),
      'detail_scan': ('W26–32 4D/5D/HD Live Scan', '4D/5D HD Live Scan'),
      'scan_4d5d': ('W33–36 Growth & Position Scan', 'Growth Scan'),
    };

    testWidgets('both options render after checkout completes', (tester) async {
      await _openCheckout(tester, _preview());
      expect(find.textContaining('Imbasan Seterusnya'), findsNothing);

      await _completeCheckout(tester);

      expect(find.text('Imbasan Seterusnya: W26–32 4D/5D/HD Live Scan'), findsOneWidget);
      expect(find.text(_followUpLabel), findsOneWidget);
    });

    scanChain.forEach((completed, next) {
      testWidgets('after $completed, "Imbasan Seterusnya" books ${next.$2}', (tester) async {
        final milestone = CheckoutMilestoneRule(key: completed, label: completed, bonusPoints: 0, minWeek: 0, maxWeek: 0);
        final h = await _openCheckout(tester, _preview(milestone: milestone));
        await _completeCheckout(tester);

        await _tapAndSettle(tester, find.text('Imbasan Seterusnya: ${next.$1}'));

        // Checkout closed, reporting success to the caller.
        expect(h.checkoutClosed, isTrue);
        expect(h.checkoutResult, isTrue);
        expect(find.byType(AppointmentCheckoutDialog), findsNothing);

        // Booking form opened for the same patient at the same branch.
        final form = tester.widget<AppointmentDetails>(find.byType(AppointmentDetails));
        expect(form.type, 'create');
        expect(form.initialUserId, 'usr-456');
        expect(form.initialUserName, 'Siti Nurhaliza');
        expect(form.initialUserPhone, '0123456789');
        expect(form.initialBranchId, 'br-1');
        expect(form.initialNote, 'Follow-up ${next.$1} after completing Detail Anomaly Scan');
        expect(h.api.serviceRequests, contains('br-1'));
        // The form looks up the patient's Baby Tracker EDD to pre-fill it.
        expect(h.api.babyTrackerRequests, contains('usr-456'));

        // And the user sees the patient and the next scan already chosen.
        expect(find.text('Siti Nurhaliza'), findsWidgets);
        expect(find.textContaining('0123456789'), findsWidgets);
        expect(find.text(next.$2), findsOneWidget);
      });
    });

    testWidgets('after the growth scan, the next-step button opens the form with no scan preselected',
        (tester) async {
      const growth = CheckoutMilestoneRule(key: 'growth_scan', label: 'Growth', bonusPoints: 0, minWeek: 0, maxWeek: 0);
      await _openCheckout(tester, _preview(milestone: growth, serviceName: 'Growth Scan'));
      await _completeCheckout(tester);

      await _tapAndSettle(tester, find.text('Imbasan Seterusnya: Postnatal & Newborn Care Visit'));

      final form = tester.widget<AppointmentDetails>(find.byType(AppointmentDetails));
      expect(form.initialServiceKeyword, isNull);
      expect(form.initialUserName, 'Siti Nurhaliza');
      for (final s in _branchServices) {
        expect(find.text(s.serviceName!), findsNothing);
      }
    });

    testWidgets('the re-booking form pre-fills the EDD from the patient\'s Baby Tracker', (tester) async {
      final h = await _openCheckout(tester, _preview(serviceName: 'Detail Anomaly Scan'));
      h.api.babyTrackerEdd = '2027-05-01';
      await _completeCheckout(tester);

      await _tapAndSettle(tester, find.text(_followUpLabel));

      expect(h.api.babyTrackerRequests, ['usr-456']);
      expect(find.text('01-05-2027'), findsOneWidget);
    });

    testWidgets('no EDD pre-fill once the Baby Tracker records the birth', (tester) async {
      final h = await _openCheckout(tester, _preview(serviceName: 'Detail Anomaly Scan'));
      h.api
        ..babyTrackerEdd = '2027-05-01'
        ..babyTrackerBirth = '2027-04-28';
      await _completeCheckout(tester);

      await _tapAndSettle(tester, find.text(_followUpLabel));

      expect(h.api.babyTrackerRequests, ['usr-456']);
      expect(find.text('01-05-2027'), findsNothing);
    });

    testWidgets('"Susulan / Ulang Servis Sama" re-books the same service', (tester) async {
      final h = await _openCheckout(tester, _preview(serviceName: 'Detail Anomaly Scan'));
      await _completeCheckout(tester);

      await _tapAndSettle(tester, find.text(_followUpLabel));

      expect(h.checkoutResult, isTrue);
      expect(find.byType(AppointmentCheckoutDialog), findsNothing);

      final form = tester.widget<AppointmentDetails>(find.byType(AppointmentDetails));
      expect(form.type, 'create');
      expect(form.initialUserId, 'usr-456');
      expect(form.initialUserName, 'Siti Nurhaliza');
      expect(form.initialUserPhone, '0123456789');
      expect(form.initialBranchId, 'br-1');
      expect(form.initialServiceKeyword, 'Detail Anomaly Scan');
      expect(form.initialNote, 'Routine follow-up / rescan for Detail Anomaly Scan (Review in 1–2 weeks)');

      expect(find.text('Siti Nurhaliza'), findsWidgets);
      expect(find.text('Detail Anomaly Scan'), findsOneWidget);
    });

    testWidgets('saving the re-booking refreshes the caller via onCompleted', (tester) async {
      final h = await _openCheckout(tester, _preview());
      await _completeCheckout(tester);
      expect(h.onCompletedCalls, 1); // checkout itself

      await _tapAndSettle(tester, find.text(_followUpLabel));

      final form = tester.widget<AppointmentDetails>(find.byType(AppointmentDetails));
      form.refreshData!();
      expect(h.onCompletedCalls, 2);
    });
  });
}
