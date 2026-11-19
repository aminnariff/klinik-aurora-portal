class CreateUserResponse {
  String? message;
  String? userId;
  CreateUserData? data;

  CreateUserResponse({this.message, this.userId, this.data});

  CreateUserResponse.fromJson(Map<String, dynamic> json) {
    message = json['message']?.toString();
    userId = json['userId']?.toString() ?? json['data']?['userId']?.toString();
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      data = CreateUserData.fromJson(json['data']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> res = <String, dynamic>{};
    res['message'] = message;
    res['userId'] = userId;
    if (data != null) res['data'] = data!.toJson();
    return res;
  }
}

class CreateUserData {
  String? userId;
  String? userFullName;
  String? userName;
  String? userPhone;
  String? userEmail;
  String? userNric;
  String? branchId;

  CreateUserData({
    this.userId,
    this.userFullName,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.userNric,
    this.branchId,
  });

  CreateUserData.fromJson(Map<String, dynamic> json) {
    userId = json['userId']?.toString();
    userFullName = json['userFullName']?.toString();
    userName = json['userName']?.toString();
    userPhone = json['userPhone']?.toString();
    userEmail = json['userEmail']?.toString();
    userNric = json['userNric']?.toString();
    branchId = json['branchId']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      if (userFullName != null) 'userFullName': userFullName,
      if (userName != null) 'userName': userName,
      if (userPhone != null) 'userPhone': userPhone,
      if (userEmail != null) 'userEmail': userEmail,
      if (userNric != null) 'userNric': userNric,
      if (branchId != null) 'branchId': branchId,
    };
  }
}

