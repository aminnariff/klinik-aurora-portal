class RewardHistoryResponse {
  String? message;
  List<Data>? data;
  int? totalPage;
  int? totalCount;

  RewardHistoryResponse({
    this.message,
    this.data,
    this.totalPage,
    this.totalCount,
  });

  RewardHistoryResponse.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
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

class Data {
  String? rewardHistoryId;
  String? rewardId;
  String? rewardName;
  int? rewardPoint;
  String? rewardImage;
  String? rewardDescription;
  int? rewardStatus;
  int? transactionPoint;
  String? pointTransactionId;
  String? rewardHistoryDescription;
  String? rewardHistoryImage;
  int? rewardHistoryStatus;
  String? rewardHistoryCreatedDate;
  String? rewardHistoryModifiedDate;
  String? userId;
  String? userFullname;
  String? userName;
  String? userPhone;
  String? userAddress;
  String? userAddressPostcode;
  String? userAddressCity;
  String? userAddressState;
  String? userAddressCountry;
  String? createdByEmail;
  String? createdByFullname;

  Data(
      {this.rewardHistoryId,
      this.rewardId,
      this.rewardName,
      this.rewardPoint,
      this.rewardImage,
      this.rewardDescription,
      this.rewardStatus,
      this.transactionPoint,
      this.pointTransactionId,
      this.rewardHistoryDescription,
      this.rewardHistoryImage,
      this.rewardHistoryStatus,
      this.rewardHistoryCreatedDate,
      this.rewardHistoryModifiedDate,
      this.userId,
      this.userFullname,
      this.userName,
      this.userPhone,
      this.userAddress,
      this.userAddressPostcode,
      this.userAddressCity,
      this.userAddressState,
      this.userAddressCountry,
      this.createdByEmail,
      this.createdByFullname});

  Data.fromJson(Map<String, dynamic> json) {
    rewardHistoryId = json['rewardHistoryId'];
    rewardId = json['rewardId'];
    rewardName = json['rewardName'];
    rewardPoint = json['rewardPoint'];
    rewardImage = json['rewardImage'];
    rewardDescription = json['rewardDescription'];
    rewardStatus = json['rewardStatus'];
    transactionPoint = json['transactionPoint'];
    pointTransactionId = json['pointTransactionId'];
    rewardHistoryDescription = json['rewardHistoryDescription'];
    rewardHistoryImage = json['rewardHistoryImage'];
    rewardHistoryStatus = json['rewardHistoryStatus'];
    rewardHistoryCreatedDate = json['rewardHistoryCreatedDate'];
    rewardHistoryModifiedDate = json['rewardHistoryModifiedDate'];
    userId = json['userId'];
    userFullname = json['userFullname'];
    userName = json['userName'];
    userPhone = json['userPhone'];
    userAddress = json['userAddress'];
    userAddressPostcode = json['userAddressPostcode'];
    userAddressCity = json['userAddressCity'];
    userAddressState = json['userAddressState'];
    userAddressCountry = json['userAddressCountry'];
    createdByEmail = json['createdByEmail'];
    createdByFullname = json['createdByFullname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rewardHistoryId'] = rewardHistoryId;
    data['rewardId'] = rewardId;
    data['rewardName'] = rewardName;
    data['rewardPoint'] = rewardPoint;
    data['rewardImage'] = rewardImage;
    data['rewardDescription'] = rewardDescription;
    data['rewardStatus'] = rewardStatus;
    data['transactionPoint'] = transactionPoint;
    data['pointTransactionId'] = pointTransactionId;
    data['rewardHistoryDescription'] = rewardHistoryDescription;
    data['rewardHistoryImage'] = rewardHistoryImage;
    data['rewardHistoryStatus'] = rewardHistoryStatus;
    data['rewardHistoryCreatedDate'] = rewardHistoryCreatedDate;
    data['rewardHistoryModifiedDate'] = rewardHistoryModifiedDate;
    data['userId'] = userId;
    data['userFullname'] = userFullname;
    data['userName'] = userName;
    data['userPhone'] = userPhone;
    data['userAddress'] = userAddress;
    data['userAddressPostcode'] = userAddressPostcode;
    data['userAddressCity'] = userAddressCity;
    data['userAddressState'] = userAddressState;
    data['userAddressCountry'] = userAddressCountry;
    data['createdByEmail'] = createdByEmail;
    data['createdByFullname'] = createdByFullname;
    return data;
  }
}
