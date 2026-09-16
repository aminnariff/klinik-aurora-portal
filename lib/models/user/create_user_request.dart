class CreateUserRequest {
  String? userEmail;
  String? userPassword;
  String? userRetypePassword;
  String? userName;
  String? userFullname;
  String? userDob;
  String? branchId;
  String? userPhone;
  String? userReferral;
  String? userNric;

  CreateUserRequest(
      {this.userEmail,
      this.userPassword,
      this.userRetypePassword,
      this.userName,
      this.userFullname,
      this.userDob,
      this.branchId,
      this.userPhone,
      this.userReferral,
      this.userNric});

  CreateUserRequest.fromJson(Map<String, dynamic> json) {
    userEmail = json['userEmail'];
    userPassword = json['userPassword'];
    userRetypePassword = json['userRetypePassword'];
    userName = json['userName'];
    userFullname = json['userFullname'];
    userDob = json['userDob'];
    branchId = json['branchId'];
    userPhone = json['userPhone'];
    userReferral = json['userReferral'];
    userNric = json['userNric'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userEmail'] = userEmail;
    data['userPassword'] = userPassword;
    data['userRetypePassword'] = userRetypePassword;
    data['userName'] = userName;
    data['userFullname'] = userFullname;
    data['userDob'] = userDob;
    data['branchId'] = branchId;
    data['userPhone'] = userPhone;
    data['userReferral'] = userReferral;
    data['userNric'] = userNric;
    return data;
  }
}
