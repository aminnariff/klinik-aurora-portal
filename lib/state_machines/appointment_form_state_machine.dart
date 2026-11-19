import 'package:klinik_aurora_portal/state_machines/appointment_state_machine.dart';

/// Form modes for the unified Appointment Dialog
sealed class AppointmentFormState {
  const AppointmentFormState();

  bool get isCreate =>
      this is AppointmentFormCreateWalkIn || this is AppointmentFormCreatePreFilled;

  bool get isUpdate =>
      this is AppointmentFormUpdateEditable ||
      this is AppointmentFormCompleted ||
      this is AppointmentFormReadOnly;

  bool get isReadOnly => this is AppointmentFormReadOnly;
  bool get isCompletedView => this is AppointmentFormCompleted;

  bool get canEditSchedule =>
      this is AppointmentFormCreateWalkIn ||
      this is AppointmentFormCreatePreFilled ||
      this is AppointmentFormUpdateEditable;

  bool get isTerminal =>
      this is AppointmentFormCompleted ||
      (this is AppointmentFormReadOnly &&
          (this as AppointmentFormReadOnly).state.isTerminal);

  static AppointmentFormState resolve({
    required String type, // 'create' | 'update'
    String? userId,
    int? statusCode,
    bool isUnlocked = false,
  }) {
    if (type == 'create') {
      if (userId != null && userId.isNotEmpty) {
        return AppointmentFormCreatePreFilled(userId: userId);
      }
      return const AppointmentFormCreateWalkIn();
    }

    final state = AppointmentState.fromCode(statusCode);
    if (state == AppointmentState.completed) {
      return const AppointmentFormCompleted();
    }
    if (state.isTerminal && !isUnlocked) {
      return AppointmentFormReadOnly(state: state);
    }
    if ((state == AppointmentState.cancelled || state == AppointmentState.refunded) &&
        !isUnlocked) {
      return AppointmentFormReadOnly(state: state);
    }
    return AppointmentFormUpdateEditable(state: state);
  }
}

class AppointmentFormCreateWalkIn extends AppointmentFormState {
  const AppointmentFormCreateWalkIn();
}

class AppointmentFormCreatePreFilled extends AppointmentFormState {
  final String userId;
  const AppointmentFormCreatePreFilled({required this.userId});
}

class AppointmentFormUpdateEditable extends AppointmentFormState {
  final AppointmentState state;
  const AppointmentFormUpdateEditable({required this.state});
}

class AppointmentFormCompleted extends AppointmentFormState {
  const AppointmentFormCompleted();
}

class AppointmentFormReadOnly extends AppointmentFormState {
  final AppointmentState state;
  const AppointmentFormReadOnly({required this.state});
}
