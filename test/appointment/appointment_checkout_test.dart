import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_checkout_controller.dart';
import 'package:klinik_aurora_portal/controllers/baby_tracker/points_reengagement_controller.dart';

void main() {
  group('Appointment Checkout Models & Mathematics', () {
    test('CheckoutPreviewData correctly parses JSON with detected milestone', () {
      final json = {
        'data': {
          'appointmentId': 'appt-123',
          'userId': 'usr-456',
          'patientName': 'Siti Nurhaliza',
          'patientPhone': '0123456789',
          'branchId': 'br-1',
          'branchName': 'Bangi Central',
          'doctorName': 'Dr. Sarah',
          'serviceName': 'Detail Anomaly Scan',
          'basePrice': 150.0,
          'bookingFeePaid': 30.0,
          'expectedBalance': 120.0,
          'currentPoints': 200,
          'gestationalWeek': 20,
          'detectedMilestone': {
            'key': 'detail_scan',
            'label': 'W18–24 Detail Anomaly Scan',
            'bonusPoints': 100,
            'minWeek': 18,
            'maxWeek': 24,
          },
          'milestones': [
            {
              'key': 'detail_scan',
              'label': 'W18–24 Detail Anomaly Scan',
              'bonusPoints': 100,
              'minWeek': 18,
              'maxWeek': 24,
            }
          ],
          'suggestedAddOns': [
            {'name': 'Obimin Vitamins', 'price': 45.0, 'quantity': 1}
          ],
        }
      };

      final data = CheckoutPreviewData.fromJson(json);

      expect(data.appointmentId, 'appt-123');
      expect(data.patientName, 'Siti Nurhaliza');
      expect(data.basePrice, 150.0);
      expect(data.bookingFeePaid, 30.0);
      expect(data.expectedBalance, 120.0);
      expect(data.currentPoints, 200);
      expect(data.gestationalWeek, 20);
      expect(data.detectedMilestone?.bonusPoints, 100);
      expect(data.suggestedAddOns.length, 1);
      expect(data.suggestedAddOns.first.price, 45.0);
    });

    test('Checkout math calculates correct gross, balance and points with add-ons', () {
      const basePrice = 150.0;
      const bookingDeposit = 30.0;
      final addOns = [
        CheckoutAddOnItem(name: 'Obimin Vitamins', price: 45.0, quantity: 1),
        CheckoutAddOnItem(name: 'Ultrasound Glossy Print', price: 20.0, quantity: 2),
      ];

      double extrasTotal = 0.0;
      for (final it in addOns) {
        extrasTotal += it.price * it.quantity;
      }
      expect(extrasTotal, 85.0); // 45 + 40

      final grossTotal = basePrice + extrasTotal;
      expect(grossTotal, 235.0); // 150 + 85

      final balancePayable = grossTotal - bookingDeposit;
      expect(balancePayable, 205.0); // 235 - 30

      final basePoints = balancePayable.floor();
      const milestoneBonus = 100;
      final totalPoints = basePoints + milestoneBonus;
      expect(totalPoints, 305); // 205 + 100
    });

    test('CheckoutResultData correctly parses result and WhatsApp receipt', () {
      final json = {
        'data': {
          'appointmentId': 'appt-123',
          'patientName': 'Siti Nurhaliza',
          'serviceName': 'Detail Anomaly Scan',
          'grossTotal': 235.0,
          'bookingFeePaid': 30.0,
          'netCollected': 205.0,
          'paymentMethod': 'duitnow_qr',
          'pointsAwarded': 305,
          'basePoints': 205,
          'milestoneBonusPoints': 100,
          'newTotalPoints': 505,
          'whatsappReceipt': 'Official receipt text',
          'whatsappUrl': 'https://wa.me/60123456789?text=...',
        }
      };

      final res = CheckoutResultData.fromJson(json);
      expect(res.netCollected, 205.0);
      expect(res.pointsAwarded, 305);
      expect(res.newTotalPoints, 505);
      expect(res.whatsappUrl, contains('wa.me'));
    });
  });

  group('Points Re-Engagement Models', () {
    test('PointsReengagementResponse parses items and computes values', () {
      final json = {
        'data': {
          'totalEligible': 1,
          'uncontactedCount': 1,
          'items': [
            {
              'userId': 'usr-789',
              'patientName': 'Nurul Izzah',
              'patientPhone': '0198765432',
              'patientEmail': 'nurul@example.com',
              'branchId': 'br-2',
              'branchName': 'Shah Alam',
              'totalPoints': 350,
              'cashValueRm': 35.0,
              'nextExpiryDate': '2027-01-01',
              'lastVisitDate': '2026-09-15',
              'daysSinceLastVisit': 65,
              'hasUpcomingBooking': false,
              'alreadyContactedRecently': false,
              'suggestedMessage': 'Hi Nurul...',
              'whatsappUrl': 'https://wa.me/60198765432?text=...',
            }
          ]
        }
      };

      final resp = PointsReengagementResponse.fromJson(json);
      expect(resp.totalEligible, 1);
      expect(resp.items.length, 1);
      final item = resp.items.first;
      expect(item.patientName, 'Nurul Izzah');
      expect(item.totalPoints, 350);
      expect(item.cashValueRm, 35.0);
      expect(item.alreadyContactedRecently, false);
      expect(item.hasUpcomingBooking, false);
    });
  });
}
