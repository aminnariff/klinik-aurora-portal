class UserPointsResponse {
  String? message;
  List<Data>? data;
  int? totalCount;
  int? totalPage;

  UserPointsResponse({this.message, this.data, this.totalCount, this.totalPage});

  UserPointsResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
    totalPage = json['totalPage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['totalCount'] = totalCount;
    data['totalPage'] = totalPage;
    return data;
  }
}

class Data {
  String? transactionId;
  String? refNo;
  String? userId;
  String? username;
  String? pointDescription;
  int? pointType;
  String? voucherId;
  String? voucherName;
  String? referralUserId;
  String? referralUsername;
  int? totalPoint;
  String? createdDate;
  String? createdByEmail;
  String? createdByFullname;

  Data(
      {this.transactionId,
      this.refNo,
      this.userId,
      this.username,
      this.pointDescription,
      this.pointType,
      this.voucherId,
      this.voucherName,
      this.referralUserId,
      this.referralUsername,
      this.totalPoint,
      this.createdDate,
      this.createdByEmail,
      this.createdByFullname});

  Data.fromJson(Map<String, dynamic> json) {
    transactionId = json['transactionId'];
    refNo = json['refNo'];
    userId = json['userId'];
    username = json['username'];
    pointDescription = json['pointDescription'];
    pointType = json['pointType'];
    voucherId = json['voucherId'];
    voucherName = json['voucherName'];
    referralUserId = json['referralUserId'];
    referralUsername = json['referralUsername'];
    totalPoint = json['totalPoint'];
    createdDate = json['createdDate'];
    createdByEmail = json['createdByEmail'];
    createdByFullname = json['createdByFullname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['transactionId'] = transactionId;
    data['refNo'] = refNo;
    data['userId'] = userId;
    data['username'] = username;
    data['pointDescription'] = pointDescription;
    data['pointType'] = pointType;
    data['voucherId'] = voucherId;
    data['voucherName'] = voucherName;
    data['referralUserId'] = referralUserId;
    data['referralUsername'] = referralUsername;
    data['totalPoint'] = totalPoint;
    data['createdDate'] = createdDate;
    data['createdByEmail'] = createdByEmail;
    data['createdByFullname'] = createdByFullname;
    return data;
  }
}
