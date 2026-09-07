class CreateServiceRequest {
  String? serviceName;
  String? serviceDescription;
  double? servicePrice;
  double? serviceBookingFee;
  int? doctorType;
  String? serviceTime;
  String? serviceCategory;
  String? serviceImage;
  int? serviceStatus;
  List<String>? serviceTemplate;

  CreateServiceRequest({
    this.serviceName,
    this.serviceDescription,
    this.servicePrice,
    this.serviceBookingFee,
    this.doctorType,
    this.serviceTime,
    this.serviceCategory,
    this.serviceImage,
    this.serviceStatus,
    this.serviceTemplate,
  });

  CreateServiceRequest.fromJson(Map<String, dynamic> json) {
    serviceName = json['serviceName'];
    serviceDescription = json['serviceDescription'];
    servicePrice = json['servicePrice'];
    serviceBookingFee = json['serviceBookingFee'];
    doctorType = json['doctorType'];
    serviceTime = json['serviceTime'];
    serviceCategory = json['serviceCategory'];
    serviceImage = json['serviceImage'];
    serviceStatus = json['serviceStatus'];
    serviceTemplate = json['serviceTemplate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceName'] = serviceName;
    data['serviceDescription'] = serviceDescription;
    data['servicePrice'] = servicePrice;
    data['serviceBookingFee'] = serviceBookingFee;
    data['doctorType'] = doctorType;
    data['serviceTime'] = serviceTime;
    data['serviceCategory'] = serviceCategory;
    if (serviceImage != null) data['serviceImage'] = serviceImage;
    data['serviceStatus'] = serviceStatus;
    data['serviceTemplate'] = serviceTemplate;
    return data;
  }
}
