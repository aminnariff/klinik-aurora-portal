/// Lightweight route path and sidebar display-name constants.
///
/// Keeping route identifiers here allows [router], [Homepage], and
/// [CommandPaletteDialog] to navigate without eagerly importing heavy feature
/// libraries that are loaded lazily via Dart `deferred as` chunks.
abstract final class RouteNames {
  static const home = '/';
  static const login = '/login';
  static const noPermission = '/no-permission';
  static const passwordRecovery = '/password-recovery';
  static const deleteAccount = '/account-deletion';
  static const privacyPolicy = '/privacy-policy';
  static const termsAndConditions = '/terms-and-conditions';
  static const refundPolicy = '/refund-policy';

  static const appointments = '/appointment';
  static const appointmentsDisplay = 'Appointments';

  static const paymentMismatch = '/appointment/payment-mismatch';
  static const paymentMismatchDisplay = 'Payment Issues';

  static const patients = '/patients';
  static const patientsDisplay = 'Patients';

  static const babyTracker = '/aurora-baby';
  static const babyTrackerDisplay = 'Baby Tracker';

  static const doctors = '/pic';
  static const doctorsDisplay = 'Doctors';

  static const services = '/service';
  static const servicesDisplay = 'Services & Pricing';

  static const branches = '/branch';
  static const branchesDisplay = 'Branches';

  static const payments = '/payment-summary';
  static const paymentsDisplay = 'Payment Records';

  static const branchPaymentSummary = '/branch-payment-summary';
  static const branchPaymentSummaryDisplay = 'Branch Summary';

  static const points = '/points';
  static const pointsDisplay = 'Points';

  static const vouchers = '/voucher';
  static const vouchersDisplay = 'Vouchers';

  static const rewards = '/reward';
  static const rewardsDisplay = 'Rewards';

  static const rewardHistory = '/reward-history';
  static const rewardHistoryDisplay = 'Redemption History';

  static const marketing = '/admin/marketing';
  static const marketingDisplay = 'Campaigns';

  static const promotions = '/promotion';
  static const promotionsDisplay = 'Promotions';

  static const admins = '/admin';
  static const adminsDisplay = 'Staff Accounts';

  static const queueBoard = '/queue';
  static const queueBoardDisplay = "Today's Schedule";

  static const eodHandover = '/eod-handover';
  static const eodHandoverDisplay = 'Daily Closing (EOD)';

  static const trimesterRecalls = '/trimester-recalls';
  static const trimesterRecallsDisplay = 'Patient Follow-Up';

  static const utilizationHeatmap = '/utilization';
  static const utilizationHeatmapDisplay = 'Peak Hours & Capacity';

  static const auditLog = '/audit-log';
  static const auditLogDisplay = 'Activity Logs';
}
