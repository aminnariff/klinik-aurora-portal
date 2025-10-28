class ServiceBranchAvailableResponse {
  String? message;
  List<Data>? data;

  ServiceBranchAvailableResponse({this.message, this.data});

  ServiceBranchAvailableResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
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
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? serviceBranchId;
  String? serviceName;
  String? serviceBookingFee;
  String? servicePrice;
  int? dueDateToggle;
  int? isAdminOnly;
  String? eddRequired;

  Data({
    this.serviceBranchId,
    this.serviceName,
    this.serviceBookingFee,
    this.servicePrice,
    this.dueDateToggle,
    this.isAdminOnly,
    this.eddRequired,
  });

  Data.fromJson(Map<String, dynamic> json) {
    serviceBranchId = json['serviceBranchId'];
    serviceName = json['serviceName'];
    serviceBookingFee = json['serviceBookingFee'];
    servicePrice = json['servicePrice'];
    dueDateToggle = json['dueDateToggle'];
    isAdminOnly = json['isAdminOnly'];
    eddRequired = json['eddRequired'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceBranchId'] = serviceBranchId;
    data['serviceName'] = serviceName;
    data['serviceBookingFee'] = serviceBookingFee;
    data['servicePrice'] = servicePrice;
    data['dueDateToggle'] = dueDateToggle;
    data['isAdminOnly'] = isAdminOnly;
    data['eddRequired'] = eddRequired;
    return data;
  }
}
