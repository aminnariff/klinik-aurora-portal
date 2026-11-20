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
    milestones: const [],
    suggestedAddOns: const [],
  );
}

/// Services offered at branch `br-1`, in the order the API returns them.
final _branchServices = <sba.Data>[
  sba.Data(serviceBranchId: 'sb-growth', serviceName: 'Growth Scan'),
  sba.Data(serviceBranchId: 'sb-nt', serviceName: 'NT Dating Scan'),
  sba.Data(serviceBranchId: 'sb-detail', serviceName: 'Detail Anomaly Scan'),
  sba.Data(serviceBranchId: 'sb-4d', serviceName: '4D/5D HD Live Scan'),
];

/// Records what the dialogs send to the API and answers with canned data.
class _FakeApi {
  _FakeApi(this.preview);

  final CheckoutPreviewData preview;
  final List<Map<String, Object?>> submissions = [];
  final List<String?> serviceRequests = [];

  Future<ApiResponse<CheckoutPreviewData>> loadPreview(BuildContext context, String appointmentId) async {
    return ApiResponse(code: 200, data: preview);
  }

  Future<ApiResponse<CheckoutResultData>> submit(
    BuildContext context,
    String appointmentId, {
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
        grossTotal: basePrice,
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
  expect(find.text('Counter Checkout & Points Calculator'), findsOneWidget);
  return harness;
}

/// The value text of a receipt row (label on the left, amount on the right).
String _receiptAmount(WidgetTester tester, String label) {
  final row = find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
  final texts = tester.widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)));
  return texts.last.data!;
}

Future<void> _setField(WidgetTester tester, String label, String value) async {
  final field = find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
    matching: find.byType(TextField),
  );
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _completeCheckout(WidgetTester tester) async {
  final button = find.textContaining('Complete & Credit');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.text('Visit Completed & Receipt Generated'), findsOneWidget);
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
    final chain = <String?, (String title, String? keyword)>{
      'nt_scan': ('W18–24 Detail Anomaly Scan', 'detail'),
      'detail_scan': ('W26–32 4D/5D HD Live Baby Scan', '4d'),
      'scan_4d5d': ('W33–36 Growth & Position Doppler Scan', 'growth'),
      'growth_scan': ('Postnatal & Newborn Care Visit', null),
      null: ('Next Follow-Up Appointment', null),
      'postnatal': ('Next Follow-Up Appointment', null),
    };

    chain.forEach((completed, expected) {
      test('after ${completed ?? 'no milestone'} → ${expected.$1}', () {
        final next = nextMilestoneAfter(completed);
        expect(next.title, expected.$1);
        expect(next.serviceKeyword, expected.$2);
      });
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
    testWidgets('balance collectable = gross bill − online booking fee', (tester) async {
      final h = await _openCheckout(tester, _preview(basePrice: 150, bookingFeePaid: 30));

      expect(_receiptAmount(tester, 'Gross Subtotal'), 'RM 150.00');
      expect(_receiptAmount(tester, 'Less Online Deposit'), '-RM 30.00');
      expect(_receiptAmount(tester, 'Balance Payable at Counter:'), 'RM 120.00');

      // Add-ons bought at the counter raise the gross bill; the fee still comes off it.
      await _tapAndSettle(tester, find.text('+ Obimin Vitamins (RM 45)'));
      await _tapAndSettle(tester, find.text('+ Photo Print (RM 20)'));
      await _tapAndSettle(tester, find.text('+ Photo Print (RM 20)'));

      expect(_receiptAmount(tester, 'Add-on Items (2)'), '+RM 85.00');
      expect(_receiptAmount(tester, 'Gross Subtotal'), 'RM 235.00');
      expect(_receiptAmount(tester, 'Balance Payable at Counter:'), 'RM 205.00');

      await _completeCheckout(tester);
      expect(h.api.submissions.single['basePrice'], 150.0);
      expect(h.api.submissions.single['bookingFeePaid'], 30.0);
      expect(h.api.submissions.single['netCollected'], 205.0);
    });

    testWidgets('balance never goes negative when the booking fee exceeds the bill', (tester) async {
      await _openCheckout(tester, _preview(basePrice: 20, bookingFeePaid: 30));

      expect(_receiptAmount(tester, 'Balance Payable at Counter:'), 'RM 0.00');
      expect(find.text('Complete & Credit 0 Pts'), findsOneWidget);
    });

    testWidgets('editing the base price or fee recomputes the balance live', (tester) async {
      await _openCheckout(tester, _preview(basePrice: 150, bookingFeePaid: 30));

      await _setField(tester, 'Base Service (RM)', '280.50');
      await _setField(tester, 'Online Booking Fee (RM)', '50');

      expect(_receiptAmount(tester, 'Gross Subtotal'), 'RM 280.50');
      expect(_receiptAmount(tester, 'Balance Payable at Counter:'), 'RM 230.50');
    });
  });

  group('Cashier points: floor(amount collected at counter / 10)', () {
    // Points are earned on what the cashier collects, i.e. the gross bill
    // after the online booking fee. This matches the API, which recomputes
    // floor(netCollected / 10) server side. With no booking fee the balance
    // equals the gross bill, so it is floor(totalGross / 10).
    final cases = <(double gross, double fee, int points)>[
      (150, 0, 15), //  no fee: floor(150 / 10)
      (159.99, 0, 15), //  rounds down, never up
      (9.99, 0, 0), //  under RM 10 earns nothing
      (10, 0, 1), //  exactly RM 10
      (150, 30, 12), //  fee paid online: floor(120 / 10)
      (215, 30, 18), //  floor(185 / 10), not 18.5
    ];

    for (final (gross, fee, points) in cases) {
      testWidgets('gross RM $gross, fee RM $fee → $points pts', (tester) async {
        final h = await _openCheckout(tester, _preview(basePrice: gross, bookingFeePaid: fee, currentPoints: 200));

        expect(find.text('Complete & Credit $points Pts'), findsOneWidget);
        expect(find.textContaining('+$points pts', findRichText: true), findsOneWidget);
        expect(find.textContaining('(200 ➔ ${200 + points} pts)', findRichText: true), findsOneWidget);

        await _completeCheckout(tester);
        expect(h.api.submissions.single['basePoints'], points);
        expect(h.api.submissions.single['milestoneBonusPoints'], 0);
      });
    }

    testWidgets('add-ons earn points through the gross bill', (tester) async {
      final h = await _openCheckout(tester, _preview(basePrice: 100, bookingFeePaid: 0));

      expect(find.text('Complete & Credit 10 Pts'), findsOneWidget);
      await _tapAndSettle(tester, find.text('+ Blood Screen (RM 60)'));
      expect(find.text('Complete & Credit 16 Pts'), findsOneWidget);

      await _completeCheckout(tester);
      expect(h.api.submissions.single['basePoints'], 16);
    });
  });

  // ── Dual re-booking after checkout ─────────────────────────────────────

  group('Dual re-booking buttons on the receipt', () {
    final scanChain = <String, (String title, String service)>{
      'nt_scan': ('W18–24 Detail Anomaly Scan', 'Detail Anomaly Scan'),
      'detail_scan': ('W26–32 4D/5D HD Live Baby Scan', '4D/5D HD Live Scan'),
      'scan_4d5d': ('W33–36 Growth & Position Doppler Scan', 'Growth Scan'),
    };

    testWidgets('both options render after checkout completes', (tester) async {
      await _openCheckout(tester, _preview());
      expect(find.textContaining('Imbasan Seterusnya'), findsNothing);

      await _completeCheckout(tester);

      expect(find.text('Imbasan Seterusnya: W26–32 4D/5D HD Live Baby Scan'), findsOneWidget);
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
