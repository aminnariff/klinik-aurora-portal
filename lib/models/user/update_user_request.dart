class UpdateUserRequest {
  String? userId;
  String? userName;
  String? userFullname;
  String? branchId;
  String? userPhone;
  String? userDob;
  int? userStatus;

  UpdateUserRequest({
    this.userId,
    this.userName,
    this.userFullname,
    this.branchId,
    this.userPhone,
    this.userStatus,
    this.userDob,
  });

  UpdateUserRequest.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    userName = json['userName'];
    userFullname = json['userFullname'];
    branchId = json['branchId'];
    userPhone = json['userPhone'];
    userStatus = json['userStatus'];
    userDob = json['userDob'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['userName'] = userName;
    data['userFullname'] = userFullname;
    data['branchId'] = branchId;
    data['userPhone'] = userPhone;
    data['userStatus'] = userStatus;
    data['userDob'] = userDob;
    return data;
  }
}
