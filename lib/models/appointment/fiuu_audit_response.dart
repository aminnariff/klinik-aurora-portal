class FiuuAuditResponse {
  String? message;
  int? scanned;
  int? confirmedFailed;
  int? apiErrors;
  List<FiuuAuditDiscrepancy>? discrepancies;
  int? nextOffset;
  bool? hasMore;

  FiuuAuditResponse({
    this.message,
    this.scanned,
    this.confirmedFailed,
    this.apiErrors,
    this.discrepancies,
    this.nextOffset,
    this.hasMore,
  });

  FiuuAuditResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    scanned = json['scanned'];
    confirmedFailed = json['confirmedFailed'];
    apiErrors = json['apiErrors'];
    if (json['discrepancies'] != null) {
      discrepancies = <FiuuAuditDiscrepancy>[];
      json['discrepancies'].forEach((v) {
        discrepancies!.add(FiuuAuditDiscrepancy.fromJson(v));
      });
    }
    nextOffset = json['nextOffset'];
    hasMore = json['hasMore'];
  }
}

/// A Fiuu transaction we have recorded as NOT paid, but Fiuu's own status
/// API confirms was actually paid — see admin/appointment/audit-fiuu-payments.ts.
class FiuuAuditDiscrepancy {
  String? transactionId;
  String? billId;
  String? paymentGateway;
  String? paymentAmount;
  String? currentState;
  String? createdDate;
  String? paymentId;
  int? paymentStatus;
  String? appointmentId;
  int? appointmentStatus;
  int? appointmentIsDeleted;
  String? userName;
  String? userPhone;
  String? branchName;
  String? fiuuStatus;

  FiuuAuditDiscrepancy({
    this.transactionId,
    this.billId,
    this.paymentGateway,
    this.paymentAmount,
    this.currentState,
    this.createdDate,
    this.paymentId,
    this.paymentStatus,
    this.appointmentId,
    this.appointmentStatus,
    this.appointmentIsDeleted,
    this.userName,
    this.userPhone,
    this.branchName,
    this.fiuuStatus,
  });

  FiuuAuditDiscrepancy.fromJson(Map<String, dynamic> json) {
    transactionId = json['transactionId'];
    billId = json['billId'];
    paymentGateway = json['paymentGateway'];
    paymentAmount = json['paymentAmount']?.toString();
    currentState = json['currentState'];
    createdDate = json['createdDate'];
    paymentId = json['paymentId'];
    paymentStatus = json['paymentStatus'];
    appointmentId = json['appointmentId'];
    appointmentStatus = json['appointmentStatus'];
    appointmentIsDeleted = json['appointmentIsDeleted'];
    userName = json['userName'];
    userPhone = json['userPhone'];
    branchName = json['branchName'];
    fiuuStatus = json['fiuuStatus'];
  }

  String get gatewayLabel {
    if (paymentGateway == 'fiuu_1' || paymentGateway == 'fiuu_2') return 'Fiuu';
    return paymentGateway ?? '—';
  }
}
