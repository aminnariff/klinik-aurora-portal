import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/state_machines/appointment_state_machine.dart';
import 'package:klinik_aurora_portal/state_machines/appointment_form_state_machine.dart';

void main() {
  group('AppointmentState Machine', () {
    test('parses status codes correctly from int and string', () {
      expect(AppointmentState.fromCode(1), AppointmentState.booked);
      expect(AppointmentState.fromCode('1'), AppointmentState.booked);
      expect(AppointmentState.fromCode(2), AppointmentState.cancelled);
      expect(AppointmentState.fromCode(3), AppointmentState.rescheduled);
      expect(AppointmentState.fromCode(4), AppointmentState.pendingPayment);
      expect(AppointmentState.fromCode(5), AppointmentState.completed);
      expect(AppointmentState.fromCode(6), AppointmentState.refunded);
      expect(AppointmentState.fromCode(7), AppointmentState.noShow);
      expect(AppointmentState.fromCode(8), AppointmentState.transferred);
      expect(AppointmentState.fromCode(null), AppointmentState.booked);
      expect(AppointmentState.fromCode(999), AppointmentState.booked);
    });

    test('terminal states correctly identified', () {
      expect(AppointmentState.completed.isTerminal, isTrue);
      expect(AppointmentState.refunded.isTerminal, isTrue);
      expect(AppointmentState.noShow.isTerminal, isTrue);
      expect(AppointmentState.transferred.isTerminal, isTrue);

      expect(AppointmentState.booked.isTerminal, isFalse);
      expect(AppointmentState.pendingPayment.isTerminal, isFalse);
      expect(AppointmentState.rescheduled.isTerminal, isFalse);
      expect(AppointmentState.cancelled.isTerminal, isFalse); // Can transition to refunded
    });

    test('action query flags operate correctly', () {
      // Completed checks
      expect(AppointmentState.booked.canBeCompleted, isTrue);
      expect(AppointmentState.rescheduled.canBeCompleted, isTrue);
      expect(AppointmentState.completed.canBeCompleted, isFalse);
      expect(AppointmentState.cancelled.canBeCompleted, isFalse);

      // Refund checks
      expect(AppointmentState.cancelled.canBeRefunded, isTrue);
      expect(AppointmentState.booked.canBeRefunded, isFalse);
      expect(AppointmentState.completed.canBeRefunded, isFalse);

      // Transfer checks
      expect(AppointmentState.booked.canBeTransferred, isTrue);
      expect(AppointmentState.rescheduled.canBeTransferred, isTrue);
      expect(AppointmentState.completed.canBeTransferred, isFalse);
    });

    test('legal transitions enforce clinical workflow invariants', () {
      // Booked transitions
      expect(AppointmentState.booked.canTransitionTo(AppointmentState.completed), isTrue);
      expect(AppointmentState.booked.canTransitionTo(AppointmentState.cancelled), isTrue);
      expect(AppointmentState.booked.canTransitionTo(AppointmentState.rescheduled), isTrue);
      expect(AppointmentState.booked.canTransitionTo(AppointmentState.noShow), isTrue);
      expect(AppointmentState.booked.canTransitionTo(AppointmentState.transferred), isTrue);
      expect(AppointmentState.booked.canTransitionTo(AppointmentState.refunded), isFalse);

      // Terminal Completed transitions (no departures allowed)
      expect(AppointmentState.completed.canTransitionTo(AppointmentState.booked), isFalse);
      expect(AppointmentState.completed.canTransitionTo(AppointmentState.cancelled), isFalse);
      expect(AppointmentState.completed.allowedNextStates, isEmpty);

      // Cancelled can only transition to Refunded
      expect(AppointmentState.cancelled.allowedNextStates, [AppointmentState.refunded]);
    });
  });

  group('AppointmentFormState Resolution', () {
    test('resolves create mode to CreateWalkIn or CreatePreFilled', () {
      expect(
        AppointmentFormState.resolve(type: 'create'),
        isA<AppointmentFormCreateWalkIn>(),
      );
      expect(
        AppointmentFormState.resolve(type: 'create', userId: 'user-123'),
        isA<AppointmentFormCreatePreFilled>(),
      );
    });

    test('resolves update mode based on appointment status', () {
      // Editable state (Booked)
      final bookedForm = AppointmentFormState.resolve(type: 'update', statusCode: 1);
      expect(bookedForm, isA<AppointmentFormUpdateEditable>());
      expect(bookedForm.canEditSchedule, isTrue);
      expect(bookedForm.isTerminal, isFalse);

      // Completed state
      final completedForm = AppointmentFormState.resolve(type: 'update', statusCode: 5);
      expect(completedForm, isA<AppointmentFormCompleted>());
      expect(completedForm.canEditSchedule, isFalse);
      expect(completedForm.isTerminal, isTrue);

      // Cancelled state (locked unless unlocked)
      final cancelledLocked = AppointmentFormState.resolve(type: 'update', statusCode: 2, isUnlocked: false);
      expect(cancelledLocked, isA<AppointmentFormReadOnly>());
      expect(cancelledLocked.canEditSchedule, isFalse);

      final cancelledUnlocked = AppointmentFormState.resolve(type: 'update', statusCode: 2, isUnlocked: true);
      expect(cancelledUnlocked, isA<AppointmentFormUpdateEditable>());
      expect(cancelledUnlocked.canEditSchedule, isTrue);
    });
  });
}
