import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/appointment/appointment_detail_view.dart';
import 'package:klinik_aurora_portal/views/service/pregnancy_scan_settings_card.dart';

void main() {
  group('GestationalRangeValue (service.edd_required)', () {
    test('parses and formats the stored "11w0d-13w6d" format', () {
      final r = GestationalRangeValue.tryParse('11w0d-13w6d')!;
      expect([r.startDay, r.endDay], [77, 97]);
      expect(r.toString(), '11w0d-13w6d');
      expect(GestationalRangeValue.tryParse(' 18W0D – 24w6d ')!.toString(), '18w0d-24w6d');
    });

    test('rejects empty, malformed and out-of-picker values', () {
      for (final bad in [null, '', '11-13', '11w7d-13w0d', '50w0d-52w0d']) {
        expect(GestationalRangeValue.tryParse(bad), isNull, reason: '$bad');
      }
    });

    test('a range ending before it starts is invalid', () {
      expect(const GestationalRangeValue(13, 6, 11, 0).isValid, isFalse);
      expect(const GestationalRangeValue(11, 0, 11, 0).isValid, isTrue);
    });
  });

  group('pregnancyTypeMismatch (appointment detail)', () {
    test('twin mother booked a single-pregnancy service', () {
      expect(pregnancyTypeMismatch(2, 'single'), contains('twin version'));
    });

    test('single mother booked a twin service', () {
      expect(pregnancyTypeMismatch(1, 'twin'), contains('twin service'));
    });

    test('no warning when they agree, the service is for both, or there is no profile', () {
      expect(pregnancyTypeMismatch(2, 'twin'), isNull);
      expect(pregnancyTypeMismatch(1, 'single'), isNull);
      expect(pregnancyTypeMismatch(2, null), isNull);
      expect(pregnancyTypeMismatch(null, 'twin'), isNull);
    });
  });
}
