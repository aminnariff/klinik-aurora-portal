class UpdateRewardHistoryRequest {
  String? rewardId;
  String? rewardHistoryId;
  String? pointTransactionId;
  int? rewardHistoryStatus;
  String? rewardHistoryDescription;
  String? userAddress;
  String? userAddressPostcode;
  String? userAddressCity;
  String? userAddressState;
  String? userAddressCountry;

  UpdateRewardHistoryRequest({
    this.rewardId,
    this.rewardHistoryId,
    this.pointTransactionId,
    this.rewardHistoryStatus,
    this.rewardHistoryDescription,
    this.userAddress,
    this.userAddressPostcode,
    this.userAddressCity,
    this.userAddressState,
    this.userAddressCountry,
  });

  UpdateRewardHistoryRequest.fromJson(Map<String, dynamic> json) {
    rewardId = json['rewardId'];
    rewardHistoryId = json['rewardHistoryId'];
    pointTransactionId = json['pointTransactionId'];
    rewardHistoryStatus = json['rewardHistoryStatus'];
    rewardHistoryDescription = json['rewardHistoryDescription'];
    userAddress = json['userAddress'];
    userAddressPostcode = json['userAddressPostcode'];
    userAddressCity = json['userAddressCity'];
    userAddressState = json['userAddressState'];
    userAddressCountry = json['userAddressCountry'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rewardId'] = rewardId;
    data['rewardHistoryId'] = rewardHistoryId;
    data['pointTransactionId'] = pointTransactionId;
    data['rewardHistoryStatus'] = rewardHistoryStatus;
    data['rewardHistoryDescription'] = rewardHistoryDescription;
    data['userAddress'] = userAddress;
    data['userAddressPostcode'] = userAddressPostcode;
    data['userAddressCity'] = userAddressCity;
    data['userAddressState'] = userAddressState;
    data['userAddressCountry'] = userAddressCountry;
    return data;
  }
}
