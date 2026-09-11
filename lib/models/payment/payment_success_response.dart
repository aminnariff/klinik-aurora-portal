class PaymentSuccessResponse {
  String? message;
  String? branchId;
  String? branchName;
  Filters? filters;
  Range? range;
  int? total;
  List<String>? data;
  List<PaymentAppointmentItem>? items;

  PaymentSuccessResponse({
    this.message,
    this.branchId,
    this.branchName,
    this.filters,
    this.range,
    this.total,
    this.data,
    this.items,
  });

  PaymentSuccessResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    branchId = json['branchId'];
    branchName = json['branchName'];
    filters = json['filters'] != null ? Filters.fromJson(json['filters']) : null;
    range = json['range'] != null ? Range.fromJson(json['range']) : null;
    total = json['total'];
    if (json['data'] != null) {
      data = json['data'].cast<String>();
    }
    if (json['items'] != null) {
      items = <PaymentAppointmentItem>[];
      json['items'].forEach((v) {
        items!.add(PaymentAppointmentItem.fromJson(v));
      });
    }
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
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PaymentAppointmentItem {
  String? appointmentId;
  String? patientName;
  String? patientPhone;
  String? patientEmail;
  String? serviceName;
  String? branchName;
  String? appointmentDatetime;
  String? paymentAmount;
  String? paymentStatus;
  String? paymentChannel;

  PaymentAppointmentItem({
    this.appointmentId,
    this.patientName,
    this.patientPhone,
    this.patientEmail,
    this.serviceName,
    this.branchName,
    this.appointmentDatetime,
    this.paymentAmount,
    this.paymentStatus,
    this.paymentChannel,
  });

  PaymentAppointmentItem.fromJson(Map<String, dynamic> json) {
    appointmentId = json['appointmentId'];
    patientName = json['patientName'];
    patientPhone = json['patientPhone'];
    patientEmail = json['patientEmail'];
    serviceName = json['serviceName'];
    branchName = json['branchName'];
    appointmentDatetime = json['appointmentDatetime'];
    paymentAmount = json['paymentAmount']?.toString();
    paymentStatus = json['paymentStatus'];
    paymentChannel = json['paymentChannel'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appointmentId'] = appointmentId;
    data['patientName'] = patientName;
    data['patientPhone'] = patientPhone;
    data['patientEmail'] = patientEmail;
    data['serviceName'] = serviceName;
    data['branchName'] = branchName;
    data['appointmentDatetime'] = appointmentDatetime;
    data['paymentAmount'] = paymentAmount;
    data['paymentStatus'] = paymentStatus;
    data['paymentChannel'] = paymentChannel;
    return data;
  }
}

class Filters {
  String? date;
  String? status;

  Filters({this.date, this.status});

  Filters.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['status'] = status;
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
