class ServiceBranchAvailableDtResponse {
  String? message;
  List<Data>? data;
  int? totalCount;
  int? totalPage;

  ServiceBranchAvailableDtResponse({this.message, this.data, this.totalCount, this.totalPage});

  ServiceBranchAvailableDtResponse.fromJson(Map<String, dynamic> json) {
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
  String? serviceBranchAvailableDatetimeId;
  String? serviceBranchId;
  String? branchId;
  String? serviceId;
  List<String>? availableDatetimes;
  String? createdDate;
  String? modifiedDate;

  Data({
    this.serviceBranchAvailableDatetimeId,
    this.serviceBranchId,
    this.branchId,
    this.serviceId,
    this.availableDatetimes,
    this.createdDate,
    this.modifiedDate,
  });

  Data.fromJson(Map<String, dynamic> json) {
    serviceBranchAvailableDatetimeId = json['serviceBranchAvailableDatetimeId'];
    serviceBranchId = json['serviceBranchId'];
    branchId = json['branchId'];
    serviceId = json['serviceId'];
    availableDatetimes = json['availableDatetimes'].cast<String>();
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceBranchAvailableDatetimeId'] = serviceBranchAvailableDatetimeId;
    data['serviceBranchId'] = serviceBranchId;
    data['branchId'] = branchId;
    data['serviceId'] = serviceId;
    data['availableDatetimes'] = availableDatetimes;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
