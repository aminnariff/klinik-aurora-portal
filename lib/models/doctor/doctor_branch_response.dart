class DoctorBranchResponse {
  String? message;
  List<Data>? data;

  DoctorBranchResponse({this.message, this.data});

  DoctorBranchResponse.fromJson(Map<String, dynamic> json) {
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
  String? doctorId;
  String? doctorName;
  String? doctorPhone;
  String? branchId;
  int? doctorStatus;
  String? createdDate;
  Null modifiedDate;

  Data(
      {this.doctorId,
      this.doctorName,
      this.doctorPhone,
      this.branchId,
      this.doctorStatus,
      this.createdDate,
      this.modifiedDate});

  Data.fromJson(Map<String, dynamic> json) {
    doctorId = json['doctorId'];
    doctorName = json['doctorName'];
    doctorPhone = json['doctorPhone'];
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
    data['branchId'] = branchId;
    data['doctorStatus'] = doctorStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
