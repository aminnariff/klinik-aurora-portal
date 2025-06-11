class ServiceBranchExceptionResponse {
  String? message;
  List<Data>? data;
  int? totalCount;
  int? totalPage;

  ServiceBranchExceptionResponse({this.message, this.data, this.totalCount, this.totalPage});

  ServiceBranchExceptionResponse.fromJson(Map<String, dynamic> json) {
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
  String? serviceBranchExceptionId;
  String? serviceBranchId;
  String? branchId;
  String? serviceId;
  String? exceptionDate;
  String? exceptionTime;
  String? createdDate;
  String? modifiedDate;

  Data({
    this.serviceBranchExceptionId,
    this.serviceBranchId,
    this.branchId,
    this.serviceId,
    this.exceptionDate,
    this.exceptionTime,
    this.createdDate,
    this.modifiedDate,
  });

  Data.fromJson(Map<String, dynamic> json) {
    serviceBranchExceptionId = json['serviceBranchExceptionId'];
    serviceBranchId = json['serviceBranchId'];
    branchId = json['branchId'];
    serviceId = json['serviceId'];
    exceptionDate = json['exceptionDate'];
    exceptionTime = json['exceptionTime'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceBranchExceptionId'] = serviceBranchExceptionId;
    data['serviceBranchId'] = serviceBranchId;
    data['branchId'] = branchId;
    data['serviceId'] = serviceId;
    data['exceptionDate'] = exceptionDate;
    data['exceptionTime'] = exceptionTime;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
