class ServiceBranchResponse {
  String? message;
  List<Data>? data;
  int? totalCount;
  int? totalPage;

  ServiceBranchResponse({this.message, this.data, this.totalCount, this.totalPage});

  ServiceBranchResponse.fromJson(Map<String, dynamic> json) {
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
  String? serviceBranchId;
  int? serviceBranchStatus;
  String? createdDate;
  String? modifiedDate;
  String? serviceId;
  String? serviceName;
  String? serviceDescription;
  String? serviceImage;
  String? serviceTime;
  String? serviceBookingFee;
  String? servicePrice;
  int? doctorType;
  String? serviceCategory;
  List<String>? serviceBranchAvailableTime;
  int? serviceStatus;
  String? branchId;
  String? branchCode;
  String? branchName;
  String? branchImage;
  int? branchStatus;

  Data({
    this.serviceBranchId,
    this.serviceBranchStatus,
    this.createdDate,
    this.modifiedDate,
    this.serviceId,
    this.serviceName,
    this.serviceDescription,
    this.serviceImage,
    this.serviceTime,
    this.servicePrice,
    this.serviceBookingFee,
    this.doctorType,
    this.serviceCategory,
    this.serviceBranchAvailableTime,
    this.serviceStatus,
    this.branchId,
    this.branchCode,
    this.branchName,
    this.branchImage,
    this.branchStatus,
  });

  Data.fromJson(Map<String, dynamic> json) {
    serviceBranchId = json['serviceBranchId'];
    serviceBranchStatus = json['serviceBranchStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
    serviceId = json['serviceId'];
    serviceName = json['serviceName'];
    serviceDescription = json['serviceDescription'];
    serviceImage = json['serviceImage'];
    serviceTime = json['serviceTime'];
    servicePrice = json['servicePrice'];
    serviceBookingFee = json['serviceBookingFee'];
    doctorType = json['doctorType'];
    serviceCategory = json['serviceCategory'];
    serviceBranchAvailableTime = json['serviceBranchAvailableTime'].cast<String>();
    serviceStatus = json['serviceStatus'];
    branchId = json['branchId'];
    branchCode = json['branchCode'];
    branchName = json['branchName'];
    branchImage = json['branchImage'];
    branchStatus = json['branchStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceBranchId'] = serviceBranchId;
    data['serviceBranchStatus'] = serviceBranchStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    data['serviceId'] = serviceId;
    data['serviceName'] = serviceName;
    data['serviceDescription'] = serviceDescription;
    data['serviceImage'] = serviceImage;
    data['serviceTime'] = serviceTime;
    data['servicePrice'] = servicePrice;
    data['serviceBookingFee'] = serviceBookingFee;
    data['doctorType'] = doctorType;
    data['serviceCategory'] = serviceCategory;
    data['serviceBranchAvailableTime'] = serviceBranchAvailableTime;
    data['serviceStatus'] = serviceStatus;
    data['branchId'] = branchId;
    data['branchCode'] = branchCode;
    data['branchName'] = branchName;
    data['branchImage'] = branchImage;
    data['branchStatus'] = branchStatus;
    return data;
  }
}
