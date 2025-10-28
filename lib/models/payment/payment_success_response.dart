class PaymentSuccessResponse {
  String? message;
  String? branchId;
  String? branchName;
  Filters? filters;
  Range? range;
  int? total;
  List<String>? data;

  PaymentSuccessResponse({
    this.message,
    this.branchId,
    this.branchName,
    this.filters,
    this.range,
    this.total,
    this.data,
  });

  PaymentSuccessResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    branchId = json['branchId'];
    branchName = json['branchName'];
    filters = json['filters'] != null ? Filters.fromJson(json['filters']) : null;
    range = json['range'] != null ? Range.fromJson(json['range']) : null;
    total = json['total'];
    data = json['data'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    data['branchId'] = branchId;
    data['branchName'] = branchName;
    if (filters != null) {
      data['filters'] = filters!.toJson();
    }
    if (range != null) {
      data['range'] = range!.toJson();
    }
    data['total'] = total;
    data['data'] = this.data;
    return data;
  }
}

class Filters {
  String? date;

  Filters({this.date});

  Filters.fromJson(Map<String, dynamic> json) {
    date = json['date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
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
