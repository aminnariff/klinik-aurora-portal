class UpdateDoctorRequest {
  String? doctorId;
  String? doctorName;
  String? branchId;
  int? doctorStatus;
  String? doctorPhone;
  String? doctorImage;

  UpdateDoctorRequest({
    this.doctorId,
    this.doctorName,
    this.branchId,
    this.doctorStatus,
    this.doctorPhone,
    this.doctorImage,
  });

  UpdateDoctorRequest.fromJson(Map<String, dynamic> json) {
    doctorId = json['doctorId'];
    doctorName = json['doctorName'];
    branchId = json['branchId'];
    doctorStatus = json['doctorStatus'];
    doctorPhone = json['doctorPhone'];
    doctorImage = json['doctorImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['doctorId'] = doctorId;
    data['doctorName'] = doctorName;
    data['branchId'] = branchId;
    data['doctorStatus'] = doctorStatus;
    data['doctorPhone'] = doctorPhone;
    data['doctorImage'] = doctorImage;
    return data;
  }
}
