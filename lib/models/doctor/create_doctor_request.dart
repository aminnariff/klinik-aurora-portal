class CreateDoctorRequest {
  String? doctorName;
  String? branchId;
  String? doctorPhone;
  String? doctorImage;
  int? doctorType;

  CreateDoctorRequest({this.doctorName, this.branchId, this.doctorPhone, this.doctorImage, this.doctorType});

  CreateDoctorRequest.fromJson(Map<String, dynamic> json) {
    doctorName = json['doctorName'];
    branchId = json['branchId'];
    doctorPhone = json['doctorPhone'];
    doctorImage = json['doctorImage'];
    doctorType = json['doctorType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['doctorName'] = doctorName;
    data['branchId'] = branchId;
    data['doctorPhone'] = doctorPhone;
    data['doctorImage'] = doctorImage;
    data['doctorType'] = doctorType;
    return data;
  }
}
