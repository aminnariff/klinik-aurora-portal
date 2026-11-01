import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart';
import 'package:klinik_aurora_portal/views/widgets/break_ui/break_ui_harness.dart';

void main() {
  group('Break-UI Adversarial Catalog & Harness Tests', () {
    test('BreakUiDataFactory produces expected catalog edge cases', () {
      final worstCase = BreakUiDataFactory.getWorstCaseAppointments();

      expect(worstCase.length, greaterThanOrEqualTo(4));

      // Row 1: Long hyphenated diacritic name & unbreakable 60+ char email
      final r1 = worstCase[0];
      expect(r1.user?.userFullName, 'Aleksandra Wiśniewska-Kowalczyk');
      expect(r1.user?.userEmail!.length, greaterThan(60));
      expect(r1.doctor?.doctorName, contains('Montgomery III'));

      // Row 2: 2-letter name & zero fee
      final r2 = worstCase[1];
      expect(r2.user?.userFullName, 'Jo');
      expect(r2.user?.userEmail, 'a@b.co');
      expect(r2.service?.serviceBookingFee, '0.00');

      // Row 3: CJK non-spaced name & extreme 7-digit currency amount
      final r3 = worstCase[2];
      expect(r3.user?.userFullName, '王秀英');
      expect(double.parse(r3.service!.servicePrice!), greaterThan(1000000));

      // Row 4: RTL string & null optional fields
      final r4 = worstCase[3];
      expect(r4.user?.userFullName, 'نور الهدى عبد الرحمن');
      expect(r4.user?.userNric, isNull);
      expect(r4.user?.userPhone, isNull);
      expect(r4.appointmentNote, isNull);
    });

    test('BreakUiDataFactory single and empty collections conform to schema', () {
      final single = BreakUiDataFactory.getSingleAppointment();
      expect(single.length, 1);
      expect(single.first, isA<Data>());

      final empty = BreakUiDataFactory.getEmptyAppointments();
      expect(empty, isEmpty);
    });
  });
}
