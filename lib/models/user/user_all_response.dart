class UserAllResponse {
  String? message;
  List<UserResponse>? data;
  int? totalPage;
  int? totalCount;

  UserAllResponse({
    this.message,
    this.data,
    this.totalPage,
    this.totalCount,
  });

  UserAllResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <UserResponse>[];
      json['data'].forEach((v) {
        data!.add(UserResponse.fromJson(v));
      });
    }
    totalPage = json['totalPage'];
    totalCount = json['totalCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['totalPage'] = totalPage;
    data['totalCount'] = totalCount;
    return data;
  }
}

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
  int? userPoints;
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
      this.userPoints,
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
    userPoints = json['userPoints'];
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
    data['userPoints'] = userPoints;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
