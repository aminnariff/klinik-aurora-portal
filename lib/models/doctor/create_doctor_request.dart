class CreateDoctorRequest {
  String? doctorName;
  String? branchId;
  String? doctorPhone;
  String? doctorImage;

  CreateDoctorRequest({this.doctorName, this.branchId, this.doctorPhone, this.doctorImage});

  CreateDoctorRequest.fromJson(Map<String, dynamic> json) {
    doctorName = json['doctorName'];
    branchId = json['branchId'];
    doctorPhone = json['doctorPhone'];
    doctorImage = json['doctorImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['doctorName'] = doctorName;
    data['branchId'] = branchId;
    data['doctorPhone'] = doctorPhone;
    data['doctorImage'] = doctorImage;
    return data;
  }
}
