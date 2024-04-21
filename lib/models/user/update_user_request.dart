class UpdateUserRequest {
  String? userId;
  String? userName;
  String? userFullname;
  String? branchId;
  String? userPhone;
  int? userStatus;

  UpdateUserRequest({this.userId, this.userName, this.userFullname, this.branchId, this.userPhone, this.userStatus});

  UpdateUserRequest.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    userName = json['userName'];
    userFullname = json['userFullname'];
    branchId = json['branchId'];
    userPhone = json['userPhone'];
    userStatus = json['userStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['userName'] = userName;
    data['userFullname'] = userFullname;
    data['branchId'] = branchId;
    data['userPhone'] = userPhone;
    data['userStatus'] = userStatus;
    return data;
  }
}
