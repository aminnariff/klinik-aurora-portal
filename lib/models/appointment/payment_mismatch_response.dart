class PaymentMismatchResponse {
  String? message;
  List<PaymentMismatchData>? data;
  int? totalCount;
  int? totalPage;
  int? page;
  int? pageSize;

  PaymentMismatchResponse({this.message, this.data, this.totalCount, this.totalPage, this.page, this.pageSize});

  PaymentMismatchResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <PaymentMismatchData>[];
      json['data'].forEach((v) {
        data!.add(PaymentMismatchData.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
    totalPage = json['totalPage'];
    page = json['page'];
    pageSize = json['pageSize'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['message'] = message;
    if (data != null) {
      json['data'] = data!.map((v) => v.toJson()).toList();
    }
    json['totalCount'] = totalCount;
    json['totalPage'] = totalPage;
    json['page'] = page;
    json['pageSize'] = pageSize;
    return json;
  }
}

/// A row where the appointment's payment succeeded but the appointment
/// itself is soft-deleted — i.e. the patient paid, but the booking isn't
/// actually in the schedule. See admin/appointment/get-payment-mismatch.ts
/// on the backend for the exact definition.
class PaymentMismatchData {
  String? appointmentId;
  String? appointmentDatetime;
  int? appointmentStatus;
  String? appointmentCreatedDate;
  String? appointmentModifiedDate;
  String? userId;
  String? userName;
  String? userPhone;
  String? userEmail;
  String? branchId;
  String? branchName;
  String? branchPhone;
  String? serviceName;
  String? paymentId;
  String? paymentAmount;
  String? paymentReceiptNo;
  String? paymentCreatedDate;
  String? paymentModifiedDate;
  String? billId;
  String? paymentGateway;
  String? paymentTransactionState;

  PaymentMismatchData({
    this.appointmentId,
    this.appointmentDatetime,
    this.appointmentStatus,
    this.appointmentCreatedDate,
    this.appointmentModifiedDate,
    this.userId,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.branchId,
    this.branchName,
    this.branchPhone,
    this.serviceName,
    this.paymentId,
    this.paymentAmount,
    this.paymentReceiptNo,
    this.paymentCreatedDate,
    this.paymentModifiedDate,
    this.billId,
    this.paymentGateway,
    this.paymentTransactionState,
  });

  PaymentMismatchData.fromJson(Map<String, dynamic> json) {
    appointmentId = json['appointmentId'];
    appointmentDatetime = json['appointmentDatetime'];
    appointmentStatus = json['appointmentStatus'];
    appointmentCreatedDate = json['appointmentCreatedDate'];
    appointmentModifiedDate = json['appointmentModifiedDate'];
    userId = json['userId'];
    userName = json['userName'];
    userPhone = json['userPhone'];
    userEmail = json['userEmail'];
    branchId = json['branchId'];
    branchName = json['branchName'];
    branchPhone = json['branchPhone'];
    serviceName = json['serviceName'];
    paymentId = json['paymentId'];
    paymentAmount = json['paymentAmount']?.toString();
    paymentReceiptNo = json['paymentReceiptNo'];
    paymentCreatedDate = json['paymentCreatedDate'];
    paymentModifiedDate = json['paymentModifiedDate'];
    billId = json['billId'];
    paymentGateway = json['paymentGateway'];
    paymentTransactionState = json['paymentTransactionState'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['appointmentId'] = appointmentId;
    json['appointmentDatetime'] = appointmentDatetime;
    json['appointmentStatus'] = appointmentStatus;
    json['appointmentCreatedDate'] = appointmentCreatedDate;
    json['appointmentModifiedDate'] = appointmentModifiedDate;
    json['userId'] = userId;
    json['userName'] = userName;
    json['userPhone'] = userPhone;
    json['userEmail'] = userEmail;
    json['branchId'] = branchId;
    json['branchName'] = branchName;
    json['branchPhone'] = branchPhone;
    json['serviceName'] = serviceName;
    json['paymentId'] = paymentId;
    json['paymentAmount'] = paymentAmount;
    json['paymentReceiptNo'] = paymentReceiptNo;
    json['paymentCreatedDate'] = paymentCreatedDate;
    json['paymentModifiedDate'] = paymentModifiedDate;
    json['billId'] = billId;
    json['paymentGateway'] = paymentGateway;
    json['paymentTransactionState'] = paymentTransactionState;
    return json;
  }

  String get gatewayLabel {
    if (paymentGateway == 'fiuu_1' || paymentGateway == 'fiuu_2') return 'Fiuu';
    if (paymentGateway == 'billplz') return 'Billplz';
    return paymentGateway ?? '—';
  }
}
