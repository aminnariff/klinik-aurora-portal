class CreateDoctorRequest {
  String? doctorName;
  String? branchId;
  String? doctorPhone;

  CreateDoctorRequest({this.doctorName, this.branchId, this.doctorPhone});

  CreateDoctorRequest.fromJson(Map<String, dynamic> json) {
    doctorName = json['doctorName'];
    branchId = json['branchId'];
    doctorPhone = json['doctorPhone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['doctorName'] = doctorName;
    data['branchId'] = branchId;
    data['doctorPhone'] = doctorPhone;
    return data;
  }
}
