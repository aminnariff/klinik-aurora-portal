import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/config/theme.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_queue_controller.dart';
import 'package:klinik_aurora_portal/controllers/audit_log/audit_log_controller.dart';
import 'package:klinik_aurora_portal/controllers/baby_tracker/patient_recall_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/eod_handover_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/utilization_heatmap_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/patient_summary_controller.dart';
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
}
