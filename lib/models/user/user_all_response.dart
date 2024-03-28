class UserResponse {
  String? userId;
  String? userEmail;
  String? userFullname;
  String? userName;
  String? userDob;
  String? branchId;
  String? userPhone;
  String? userReferral;
  int? userStatus;
  String? createdDate;
  String? modifiedDate;

  UserResponse(
      {this.userId,
      this.userEmail,
      this.userFullname,
      this.userName,
      this.userDob,
      this.branchId,
      this.userPhone,
      this.userReferral,
      this.userStatus,
      this.createdDate,
      this.modifiedDate});

  UserResponse.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    userEmail = json['userEmail'];
    userFullname = json['userFullname'];
    userName = json['userName'];
    userDob = json['userDob'];
    branchId = json['branchId'];
    userPhone = json['userPhone'];
    userReferral = json['userReferral'];
    userStatus = json['userStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['userEmail'] = userEmail;
    data['userFullname'] = userFullname;
    data['userName'] = userName;
    data['userDob'] = userDob;
    data['branchId'] = branchId;
    data['userPhone'] = userPhone;
    data['userReferral'] = userReferral;
    data['userStatus'] = userStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
