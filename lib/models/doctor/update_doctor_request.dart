class UpdateDoctorRequest {
  String? doctorId;
  String? doctorName;
  String? branchId;
  int? doctorStatus;
  String? doctorPhone;

  UpdateDoctorRequest({this.doctorId, this.doctorName, this.branchId, this.doctorStatus, this.doctorPhone});

  UpdateDoctorRequest.fromJson(Map<String, dynamic> json) {
    doctorId = json['doctorId'];
    doctorName = json['doctorName'];
    branchId = json['branchId'];
    doctorStatus = json['doctorStatus'];
    doctorPhone = json['doctorPhone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['doctorId'] = doctorId;
    data['doctorName'] = doctorName;
    data['branchId'] = branchId;
    data['doctorStatus'] = doctorStatus;
    data['doctorPhone'] = doctorPhone;
    return data;
  }
}
