class AdminAllResponse {
  String? message;
  List<Data>? data;

  AdminAllResponse({this.message, this.data});

  AdminAllResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? userId;
  String? userFullname;
  String? userName;
  String? userEmail;
  String? branchId;
  Null userStatus;
  String? createdDate;
  Null modifiedDate;

  Data(
      {this.userId,
      this.userFullname,
      this.userName,
      this.userEmail,
      this.branchId,
      this.userStatus,
      this.createdDate,
      this.modifiedDate});

  Data.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    userFullname = json['userFullname'];
    userName = json['userName'];
    userEmail = json['userEmail'];
    branchId = json['branchId'];
    userStatus = json['userStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['userFullname'] = userFullname;
    data['userName'] = userName;
    data['userEmail'] = userEmail;
    data['branchId'] = branchId;
    data['userStatus'] = userStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
