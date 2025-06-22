class ServicesResponse {
  String? message;
  List<Data>? data;
  int? totalCount;
  int? totalPage;

  ServicesResponse({this.message, this.data, this.totalCount, this.totalPage});

  ServicesResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
    totalPage = json['totalPage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['totalCount'] = totalCount;
    data['totalPage'] = totalPage;
    return data;
  }
}

class Data {
  String? serviceId;
  String? serviceName;
  String? serviceDescription;
  String? servicePrice;
  String? serviceBookingFee;
  int? doctorType;
  String? serviceTime;
  String? serviceCategory;
  String? serviceImage;
  List<String>? serviceTemplate;
  int? serviceStatus;
  String? createdDate;
  String? modifiedDate;

  Data({
    this.serviceId,
    this.serviceName,
    this.serviceDescription,
    this.servicePrice,
    this.serviceBookingFee,
    this.doctorType,
    this.serviceTime,
    this.serviceCategory,
    this.serviceImage,
    this.serviceTemplate,
    this.serviceStatus,
    this.createdDate,
    this.modifiedDate,
  });

  Data.fromJson(Map<String, dynamic> json) {
    serviceId = json['serviceId'];
    serviceName = json['serviceName'];
    serviceDescription = json['serviceDescription'];
    servicePrice = json['servicePrice'];
    serviceBookingFee = json['serviceBookingFee'];
    doctorType = json['doctorType'];
    serviceTime = json['serviceTime'];
    serviceCategory = json['serviceCategory'];
    serviceImage = json['serviceImage'];
    serviceTemplate =
        (json['serviceTemplate'] is List)
            ? List<String>.from(json['serviceTemplate'] ?? []).where((e) => e.trim().isNotEmpty).toList()
            : [];
    serviceStatus = json['serviceStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
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
    data['serviceImage'] = serviceImage;
    data['serviceTemplate'] = serviceTemplate;
    data['serviceStatus'] = serviceStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
