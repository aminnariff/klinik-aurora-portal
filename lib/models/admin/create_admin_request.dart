class CreateAdminRequest {
  String? userEmail;
  String? userPassword;
  String? userRetypePassword;
  String? userName;
  String? userFullname;
  String? branchId;
  String? userPhone;

  CreateAdminRequest({
    this.userEmail,
    this.userPassword,
    this.userRetypePassword,
    this.userName,
    this.userFullname,
    this.branchId,
    this.userPhone,
  });

  CreateAdminRequest.fromJson(Map<String, dynamic> json) {
    userEmail = json['userEmail'];
    userPassword = json['userPassword'];
    userRetypePassword = json['userRetypePassword'];
    userName = json['userName'];
    userFullname = json['userFullname'];
    branchId = json['branchId'];
    userPhone = json['userPhone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userEmail'] = userEmail;
    data['userPassword'] = userPassword;
    data['userRetypePassword'] = userRetypePassword;
    data['userName'] = userName;
    data['userFullname'] = userFullname;
    data['branchId'] = branchId;
    data['userPhone'] = userPhone;
    return data;
  }
}
