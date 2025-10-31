class BranchPaymentSummaryResponse {
  String? message;
  Filters? filters;
  Range? range;
  SummaryTotals? summaryTotals;
  List<Data>? data;

  BranchPaymentSummaryResponse({this.message, this.filters, this.range, this.summaryTotals, this.data});

  BranchPaymentSummaryResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    filters = json['filters'] != null ? Filters.fromJson(json['filters']) : null;
    range = json['range'] != null ? Range.fromJson(json['range']) : null;
    summaryTotals = json['summaryTotals'] != null ? SummaryTotals.fromJson(json['summaryTotals']) : null;
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
    if (range != null) {
      data['range'] = range!.toJson();
    }
    if (summaryTotals != null) {
      data['summaryTotals'] = summaryTotals!.toJson();
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

class Range {
  String? start;
  String? end;

  Range({this.start, this.end});

  Range.fromJson(Map<String, dynamic> json) {
    start = json['start'];
    end = json['end'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['start'] = start;
    data['end'] = end;
    return data;
  }
}

class SummaryTotals {
  int? totalPayments;
  int? successfulPayments;
  int? failedPayments;
  String? totalPaidAmount;
  String? totalRefundAmount;
  String? netRevenue;

  SummaryTotals({
    this.totalPayments,
    this.successfulPayments,
    this.failedPayments,
    this.totalPaidAmount,
    this.totalRefundAmount,
    this.netRevenue,
  });

  SummaryTotals.fromJson(Map<String, dynamic> json) {
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
