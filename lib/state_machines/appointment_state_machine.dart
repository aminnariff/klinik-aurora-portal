import 'package:flutter/material.dart';

/// Authoritative Clinical Appointment Lifecycle State Machine
enum AppointmentState {
  pendingPayment(
    4,
    'Pending Payment',
    'Menunggu Bayaran',
    Color(0xFFF59E0B),
    Color(0xFFFEF3C7),
  ),
  booked(
    1,
    'Booked',
    'Tempahan Disahkan',
    Color(0xFF3B82F6),
    Color(0xFFEFF6FF),
  ),
  rescheduled(
    3,
    'Rescheduled',
    'Jadual Ditukar',
    Color(0xFF8B5CF6),
    Color(0xFFF5F3FF),
  ),
  completed(
    5,
    'Completed',
    'Selesai Rawatan',
    Color(0xFF10B981),
    Color(0xFFECFDF5),
  ),
  cancelled(
    2,
    'Cancelled',
    'Dibatalkan',
    Color(0xFFEF4444),
    Color(0xFFFEF2F2),
  ),
  refunded(
    6,
    'Refunded',
    'Bayaran Balik',
    Color(0xFF6B7280),
    Color(0xFFF3F4F6),
  ),
  noShow(
    7,
    'No Show',
    'Tidak Hadir',
    Color(0xFFD97706),
    Color(0xFFFFFBEB),
  ),
  transferred(
    8,
    'Transferred',
    'Dipindahkan',
    Color(0xFF0284C7),
    Color(0xFFF0F9FF),
  );

  final int statusCode;
  final String label;
  final String patientLabel;
  final Color color;
  final Color softBgColor;

  const AppointmentState(
    this.statusCode,
    this.label,
    this.patientLabel,
    this.color,
    this.softBgColor,
  );

  /// Safe lookup from legacy integer code or string
  static AppointmentState fromCode(dynamic code) {
    if (code == null) return AppointmentState.booked;
    final int? parsed = code is int ? code : int.tryParse(code.toString());
    return AppointmentState.values.firstWhere(
      (s) => s.statusCode == parsed,
      orElse: () => AppointmentState.booked,
    );
  }

  /// Invariant query flags
  bool get isTerminal =>
      this == completed || this == refunded || this == noShow || this == transferred;

  bool get canBeEdited =>
      this == booked || this == rescheduled || this == pendingPayment;

  bool get canBeCompleted =>
      this == booked || this == rescheduled;

  bool get canBeCancelled =>
      this == booked || this == rescheduled || this == pendingPayment;

  bool get canBeRescheduled =>
      this == booked || this == rescheduled;

  bool get canBeTransferred =>
      this == booked || this == rescheduled;

  bool get canBeRefunded =>
      this == cancelled;

  /// Pure transition table
  List<AppointmentState> get allowedNextStates {
    switch (this) {
      case AppointmentState.pendingPayment:
        return [AppointmentState.booked, AppointmentState.cancelled];
      case AppointmentState.booked:
      case AppointmentState.rescheduled:
        return [
          AppointmentState.rescheduled,
          AppointmentState.completed,
          AppointmentState.cancelled,
          AppointmentState.noShow,
          AppointmentState.transferred,
        ];
      case AppointmentState.cancelled:
        return [AppointmentState.refunded];
      case AppointmentState.completed:
      case AppointmentState.refunded:
      case AppointmentState.noShow:
      case AppointmentState.transferred:
        return [];
    }
  }

  bool canTransitionTo(AppointmentState next) {
    if (this == next) return true;
    return allowedNextStates.contains(next);
  }
}
