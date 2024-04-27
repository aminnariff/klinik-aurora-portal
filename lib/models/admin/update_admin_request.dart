class UpdateAdminRequest {
  String? userId;
  String? userEmail;
  String? userName;
  String? userFullname;
  String? branchId;
  String? userPhone;
  int? userStatus;

  UpdateAdminRequest({
    this.userEmail,
    this.userName,
    this.userStatus,
    this.userId,
    this.userFullname,
    this.branchId,
    this.userPhone,
  });

  UpdateAdminRequest.fromJson(Map<String, dynamic> json) {
    userEmail = json['userEmail'];
    userId = json['userId'];
    userStatus = json['userStatus'];
    userName = json['userName'];
    userFullname = json['userFullname'];
    branchId = json['branchId'];
    userPhone = json['userPhone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userEmail'] = userEmail;
    data['userId'] = userId;
    data['userStatus'] = userStatus;
    data['userName'] = userName;
    data['userFullname'] = userFullname;
    data['branchId'] = branchId;
    data['userPhone'] = userPhone;
    return data;
  }
}
