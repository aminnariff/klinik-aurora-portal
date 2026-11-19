import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/config/app_theme_preset.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/config/theme.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_queue_controller.dart';
import 'package:klinik_aurora_portal/controllers/audit_log/audit_log_controller.dart';
import 'package:klinik_aurora_portal/controllers/baby_tracker/patient_recall_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/eod_handover_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/utilization_heatmap_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/patient_summary_controller.dart';
import 'package:klinik_aurora_portal/models/user/create_user_response.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/aurora_collapsible_sidebar.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/deferred_page.dart';
import 'package:klinik_aurora_portal/views/widgets/shortcuts/portal_shortcuts.dart';

void main() {
  group('New E2E feature models parse cleanly', () {
    test('QueueBoardData parses summary and items', () {
      final data = QueueBoardData.fromJson({
        'data': {
          'date': '2026-11-18',
          'queueColumnsReady': true,
          'summary': {
            'total': 3,
            'scheduled': 1,
            'checked_in': 1,
            'in_room': 1,
            'completed': 0,
            'no_show': 0,
            'avgWaitMinutes': 14,
          },
          'items': [
            {
              'appointmentId': 'appt-1',
              'userId': 'u-1',
              'patientName': 'Aisyah Rahman',
              'patientPhone': '0123456789',
              'serviceName': 'Detail Scan',
              'branchId': 'b-1',
              'branchName': 'Shah Alam',
              'appointmentDatetime': '2026-11-18 10:00:00',
              'appointmentTime': '10:00',
              'appointmentStatus': 1,
              'queueStatus': 'checked_in',
              'isPaid': true,
              'waitMinutes': 14,
            },
          ],
        },
      });
      expect(data.total, 3);
      expect(data.avgWaitMinutes, 14);
      expect(data.items.single.queueStatus, 'checked_in');
      expect(data.items.single.isPaid, isTrue);
    });

    test('EodHandoverData parses financials, alerts, and transactions', () {
      final data = EodHandoverData.fromJson({
        'data': {
          'date': '2026-11-18',
          'branchName': 'Shah Alam',
          'appointmentSummary': {'total': 12, 'completed': 10},
          'financialSummary': {
            'totalCollected': 1250.5,
            'fiuuOnlineAmount': 950.5,
            'fiuuOnlineCount': 8,
            'counterProofAmount': 300.0,
            'counterProofCount': 2,
            'totalRefundAmount': 50.0,
            'refundCount': 1,
            'netRevenue': 1200.5,
            'channelBreakdown': [
              {'channel': 'FPX', 'count': 8, 'amount': 950.5},
            ],
          },
          'reconciliationAlerts': {
            'mismatchCount': 1,
            'unpaidCompletedCount': 0,
            'pendingPaymentCount': 2,
          },
          'transactions': [],
        },
      });
      expect(data.netRevenue, 1200.5);
      expect(data.mismatchCount, 1);
      expect(data.channelBreakdown.single.channel, 'FPX');
    });

    test('PatientSummaryData parses profile, stats, and baby tracker', () {
      final data = PatientSummaryData.fromJson({
        'data': {
          'profile': {
            'userId': 'u-1',
            'userFullname': 'Nurul Iman',
            'userPhone': '0191112222',
            'totalPoint': 340,
          },
          'visitStats': {
            'totalVisits': 5,
            'completedVisits': 4,
            'noShowVisits': 1,
          },
          'babyTracker': {
            'eddDate': '2027-02-15',
            'gestationalWeek': 27,
            'trimester': 2,
            'isOverdue': false,
            'isBabyBorn': false,
            'todayKicks': 12,
          },
          'recentAppointments': [],
          'vouchers': [],
          'recentPoints': [],
        },
      });
      expect(data.profile.totalPoint, 340);
      expect(data.visitStats.noShowVisits, 1);
      expect(data.babyTracker?.gestationalWeek, 27);
    });

    test('PatientRecallResponse parses milestones and outreach status', () {
      final data = PatientRecallResponse.fromJson({
        'data': {
          'summary': {
            'totalEligible': 2,
            'unbookedCount': 1,
            'pendingOutreachCount': 1,
            'alreadyRecalledCount': 1,
            'byMilestone': {'detail_scan': 2},
          },
          'items': [
            {
              'userId': 'u-2',
              'patientName': 'Hana',
              'gestationalWeek': 20,
              'milestoneKey': 'detail_scan',
              'recommendedScan': 'Detail Scan',
              'hasBooked': false,
              'alreadyRecalled': false,
            },
          ],
        },
      });
      expect(data.pendingOutreachCount, 1);
      expect(data.items.single.gestationalWeek, 20);
    });

    test('UtilizationHeatmapData parses cells and practitioner load', () {
      final data = UtilizationHeatmapData.fromJson({
        'data': {
          'startDate': '2026-11-05',
          'endDate': '2026-11-18',
          'summary': {
            'totalCapacity': 100,
            'totalBooked': 72,
            'avgUtilizationPct': 72,
            'overloadedPractitioners': 1,
            'underutilizedPractitioners': 0,
            'unassignedAppointments': 2,
          },
          'heatmap': [
            {'dayOfWeek': 5, 'hour': 10, 'bookedCount': 8, 'capacityCount': 8, 'utilizationPct': 100},
          ],
          'peakSlots': [],
          'idleSlots': [],
          'practitionerLoad': [
            {
              'doctorId': 'd-1',
              'doctorName': 'Dr. Aina',
              'doctorType': 2,
              'branchName': 'Shah Alam',
              'shiftHours': 16,
              'capacitySlots': 32,
              'bookedCount': 30,
              'utilizationPct': 94,
              'status': 'overloaded',
            },
          ],
        },
      });
      expect(data.avgUtilizationPct, 72);
      expect(data.practitionerLoad.single.status, 'overloaded');
    });

    test('AuditLogPageResponse parses diff states and facets', () {
      final data = AuditLogPageResponse.fromJson({
        'data': [
          {
            'logId': 99,
            'adminId': 'a-1',
            'adminName': 'Admin HQ',
            'adminEmail': 'hq@aurora.my',
            'entityType': 'appointment',
            'entityId': 'appt-9',
            'action': 'TRANSFER',
            'summary': 'Transferred branch',
            'beforeState': {'branch': 'A'},
            'afterState': {'branch': 'B'},
            'createdDate': '2026-11-18 18:00:00',
          },
        ],
        'totalCount': 1,
        'totalPage': 1,
        'currentPage': 1,
        'pageSize': 25,
        'facets': {
          'entityTypes': ['appointment'],
          'actions': ['TRANSFER'],
        },
      });
      expect(data.data.single.beforeState['branch'], 'A');
      expect(data.data.single.afterState['branch'], 'B');
    });
  });

  group('KeyboardShortcutsDialog widget', () {
    testWidgets('renders all shortcut groups cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Theme(
              data: buildLightTheme(context),
              child: const Scaffold(body: KeyboardShortcutsDialog()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
      expect(find.text('GLOBAL NAVIGATION'), findsOneWidget);
      expect(find.text('CLINIC ACTIONS'), findsOneWidget);
      expect(find.text('⌘K'), findsOneWidget);
    });
  });

  group('DeferredPage route switching regression', () {
    testWidgets('never invokes target builder before target loadLibrary completes', (tester) async {
      bool libALoaded = false;
      bool libBLoaded = false;
      final libBCompleter = Completer<void>();

      Widget wrap(Widget child) => MaterialApp(
            home: Builder(
              builder: (context) => Theme(
                data: buildDarkTheme(context),
                child: child,
              ),
            ),
          );

      await tester.pumpWidget(
        wrap(
          DeferredPage(
            libraryKey: 'test-lib-a',
            loadLibrary: () async {
              libALoaded = true;
            },
            builder: (_) {
              if (!libALoaded) throw StateError('libA not loaded');
              return const Text('Loaded A');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Loaded A'), findsOneWidget);

      // Switch to libB in the same widget slot (no key) — must wait for libBCompleter
      await tester.pumpWidget(
        wrap(
          DeferredPage(
            libraryKey: 'test-lib-b',
            loadLibrary: () async {
              await libBCompleter.future;
              libBLoaded = true;
            },
            builder: (_) {
              if (!libBLoaded) throw StateError('DeferredLoadException: libB not loaded');
              return const Text('Loaded B');
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loaded B'), findsNothing);

      libBCompleter.complete();
      await tester.pumpAndSettle();
      expect(find.text('Loaded B'), findsOneWidget);
    });
  });

  group('Dark mode semantic surface & ink tokens', () {
    tearDown(() {
      syncActiveBrandTheme(preset: AuroraThemePreset.auroraPlum, isDark: false);
    });

    test('dark mode keeps all table/dialog surfaces dark and ink light', () {
      syncActiveBrandTheme(preset: AuroraThemePreset.auroraPlum, isDark: true);

      for (final surface in [
        appCanvas,
        appSurface,
        appSurfaceSubtle,
        appSurfaceElevated,
        appTableHeaderBg,
        appTableRowAlt,
        appInputFill,
      ]) {
        expect(surface.computeLuminance(), lessThan(0.08));
      }

      for (final ink in [appInkPrimary, appInkSecondary, appInkMuted]) {
        expect(ink.computeLuminance(), greaterThan(0.30));
      }
    });

    test('light mode keeps all table/dialog surfaces light and ink dark', () {
      syncActiveBrandTheme(preset: AuroraThemePreset.auroraPlum, isDark: false);

      for (final surface in [
        appCanvas,
        appSurface,
        appSurfaceSubtle,
        appSurfaceElevated,
        appTableHeaderBg,
        appTableRowAlt,
        appInputFill,
      ]) {
        expect(surface.computeLuminance(), greaterThan(0.85));
      }

      for (final ink in [appInkPrimary, appInkSecondary, appInkMuted]) {
        expect(ink.computeLuminance(), lessThan(0.25));
      }
    });

    test('CreateUserResponse correctly parses quick walk-in patient payload', () {
      final res = CreateUserResponse.fromJson({
        'message': 'Successfully create new user!',
        'userId': 'uuid-1234-abcd',
        'data': {
          'userId': 'uuid-1234-abcd',
          'userFullName': 'Farah Nabilah',
          'userName': 'walkin_01122334455',
          'userPhone': '01122334455',
          'userEmail': 'walkin.01122334455@klinikaurora.internal',
          'userNric': '980102-14-5566',
          'branchId': 'branch-1',
        },
      });

      expect(res.userId, 'uuid-1234-abcd');
      expect(res.data?.userFullName, 'Farah Nabilah');
      expect(res.data?.userPhone, '01122334455');
      expect(res.data?.userNric, '980102-14-5566');
      expect(res.data?.userEmail, 'walkin.01122334455@klinikaurora.internal');
    });

    test('AuroraCollapsibleSidebar defines 3 pinned items and 4 accordion groups', () {
      expect(AuroraCollapsibleSidebar.pinnedLabels.length, 3);
      expect(AuroraCollapsibleSidebar.pinnedLabels, contains('Dashboard'));
      expect(AuroraCollapsibleSidebar.pinnedLabels, contains(RouteNames.appointmentsDisplay));
      expect(AuroraCollapsibleSidebar.pinnedLabels, contains(RouteNames.patientsDisplay));

      expect(AuroraCollapsibleSidebar.groups.length, 4);
      final keys = AuroraCollapsibleSidebar.groups.map((g) => g.key).toList();
      expect(keys, ['clinical', 'finance', 'loyalty', 'system']);
    });
  });
}
