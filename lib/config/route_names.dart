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
  static const babyTrackerDisplay = 'Aurora Baby';

  static const doctors = '/pic';
  static const doctorsDisplay = 'Practitioners';

  static const services = '/service';
  static const servicesDisplay = 'Services';

  static const branches = '/branch';
  static const branchesDisplay = 'Branches';

  static const payments = '/payment-summary';
  static const paymentsDisplay = 'Payment Report';

  static const branchPaymentSummary = '/branch-payment-summary';
  static const branchPaymentSummaryDisplay = 'Branch Summary';

  static const points = '/points';
  static const pointsDisplay = 'Points';

  static const vouchers = '/voucher';
  static const vouchersDisplay = 'Vouchers';

  static const rewards = '/reward';
  static const rewardsDisplay = 'Rewards';

  static const rewardHistory = '/reward-history';
  static const rewardHistoryDisplay = 'Manage Rewards';

  static const marketing = '/admin/marketing';
  static const marketingDisplay = 'Campaigns';

  static const promotions = '/promotion';
  static const promotionsDisplay = 'Promotions';

  static const admins = '/admin';
  static const adminsDisplay = 'Admins';
}
