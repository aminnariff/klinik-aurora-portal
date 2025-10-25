class BranchPaymentSummaryResponse {
  String? message;
  Filters? filters;
  int? limit;
  Summary? summary;
  List<Data>? data;

  BranchPaymentSummaryResponse({this.message, this.filters, this.limit, this.summary, this.data});

  BranchPaymentSummaryResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    filters = json['filters'] != null ? Filters.fromJson(json['filters']) : null;
    limit = json['limit'];
    summary = json['summary'] != null ? Summary.fromJson(json['summary']) : null;
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (filters != null) {
      data['filters'] = filters!.toJson();
    }
    data['limit'] = limit;
    if (summary != null) {
      data['summary'] = summary!.toJson();
    }
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Filters {
  String? startDate;
  String? endDate;

  Filters({this.startDate, this.endDate});

  Filters.fromJson(Map<String, dynamic> json) {
    startDate = json['startDate'];
    endDate = json['endDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    return data;
  }
}

class Summary {
  int? totalPayments;
  String? successfulPayments;
  String? failedPayments;
  String? totalPaidAmount;
  String? totalRefundAmount;
  String? netRevenue;

  Summary({
    this.totalPayments,
    this.successfulPayments,
    this.failedPayments,
    this.totalPaidAmount,
    this.totalRefundAmount,
    this.netRevenue,
  });

  Summary.fromJson(Map<String, dynamic> json) {
    totalPayments = json['totalPayments'];
    successfulPayments = json['successfulPayments'];
    failedPayments = json['failedPayments'];
    totalPaidAmount = json['totalPaidAmount'];
    totalRefundAmount = json['totalRefundAmount'];
    netRevenue = json['netRevenue'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalPayments'] = totalPayments;
    data['successfulPayments'] = successfulPayments;
    data['failedPayments'] = failedPayments;
    data['totalPaidAmount'] = totalPaidAmount;
    data['totalRefundAmount'] = totalRefundAmount;
    data['netRevenue'] = netRevenue;
    return data;
  }
}

class Data {
  String? branchId;
  String? branchName;
  int? totalPayments;
  String? successfulPayments;
  String? failedPayments;
  String? totalPaidAmount;
  String? totalRefundAmount;
  String? netRevenue;

  Data({
    this.branchId,
    this.branchName,
    this.totalPayments,
    this.successfulPayments,
    this.failedPayments,
    this.totalPaidAmount,
    this.totalRefundAmount,
    this.netRevenue,
  });

  Data.fromJson(Map<String, dynamic> json) {
    branchId = json['branchId'];
    branchName = json['branchName'];
    totalPayments = json['totalPayments'];
    successfulPayments = json['successfulPayments'];
    failedPayments = json['failedPayments'];
    totalPaidAmount = json['totalPaidAmount'];
    totalRefundAmount = json['totalRefundAmount'];
    netRevenue = json['netRevenue'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['branchId'] = branchId;
    data['branchName'] = branchName;
    data['totalPayments'] = totalPayments;
    data['successfulPayments'] = successfulPayments;
    data['failedPayments'] = failedPayments;
    data['totalPaidAmount'] = totalPaidAmount;
    data['totalRefundAmount'] = totalRefundAmount;
    data['netRevenue'] = netRevenue;
    return data;
  }
}
