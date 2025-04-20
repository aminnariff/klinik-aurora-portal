class UpdateServiceRequest {
  String? serviceId;
  String? serviceName;
  String? serviceDescription;
  double? servicePrice;
  double? serviceBookingFee;
  int? doctorType;
  String? serviceTime;
  String? serviceCategory;
  int? serviceStatus;

  UpdateServiceRequest(
      {this.serviceId,
      this.serviceName,
      this.serviceDescription,
      this.servicePrice,
      this.serviceBookingFee,
      this.doctorType,
      this.serviceTime,
      this.serviceCategory,
      this.serviceStatus});

  UpdateServiceRequest.fromJson(Map<String, dynamic> json) {
    serviceId = json['serviceId'];
    serviceName = json['serviceName'];
    serviceDescription = json['serviceDescription'];
    servicePrice = json['servicePrice'];
    serviceBookingFee = json['serviceBookingFee'];
    doctorType = json['doctorType'];
    serviceTime = json['serviceTime'];
    serviceCategory = json['serviceCategory'];
    serviceStatus = json['serviceStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceId'] = serviceId;
    data['serviceName'] = serviceName;
    data['serviceDescription'] = serviceDescription;
    data['servicePrice'] = servicePrice;
    data['serviceBookingFee'] = serviceBookingFee;
    data['doctorType'] = doctorType;
    data['serviceTime'] = serviceTime;
    data['serviceCategory'] = serviceCategory;
    data['serviceStatus'] = serviceStatus;
    return data;
  }
}
