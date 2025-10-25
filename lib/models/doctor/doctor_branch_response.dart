class DoctorBranchResponse {
  String? message;
  List<Data>? data;
  int? totalPage;
  int? totalCount;

  DoctorBranchResponse({this.message, this.data, this.totalPage, this.totalCount});

  DoctorBranchResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    totalPage = json['totalPage'];
    totalCount = json['totalCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['totalPage'] = totalPage;
    data['totalCount'] = totalCount;
    return data;
  }
}

class Data {
  String? doctorId;
  String? doctorName;
  String? doctorPhone;
  String? branchId;
  String? doctorImage;
  int? doctorStatus;
  String? createdDate;
  String? modifiedDate;

  Data({
    this.doctorId,
    this.doctorName,
    this.doctorPhone,
    this.doctorImage,
    this.branchId,
    this.doctorStatus,
    this.createdDate,
    this.modifiedDate,
  });

  Data.fromJson(Map<String, dynamic> json) {
    doctorId = json['doctorId'];
    doctorName = json['doctorName'];
    doctorPhone = json['doctorPhone'];
    doctorImage = json['doctorImage'];
    branchId = json['branchId'];
    doctorStatus = json['doctorStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['doctorId'] = doctorId;
    data['doctorName'] = doctorName;
    data['doctorPhone'] = doctorPhone;
    data['doctorImage'] = doctorImage;
    data['branchId'] = branchId;
    data['doctorStatus'] = doctorStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
