class UpdateRewardHistoryRequest {
  String? rewardId;
  String? rewardHistoryId;
  String? pointTransactionId;
  int? rewardHistoryStatus;
  String? rewardHistoryDescription;

  UpdateRewardHistoryRequest({
    this.rewardId,
    this.rewardHistoryId,
    this.pointTransactionId,
    this.rewardHistoryStatus,
    this.rewardHistoryDescription,
  });

  UpdateRewardHistoryRequest.fromJson(Map<String, dynamic> json) {
    rewardId = json['rewardId'];
    rewardHistoryId = json['rewardHistoryId'];
    pointTransactionId = json['pointTransactionId'];
    rewardHistoryStatus = json['rewardHistoryStatus'];
    rewardHistoryDescription = json['rewardHistoryDescription'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rewardId'] = rewardId;
    data['rewardHistoryId'] = rewardHistoryId;
    data['pointTransactionId'] = pointTransactionId;
    data['rewardHistoryStatus'] = rewardHistoryStatus;
    data['rewardHistoryDescription'] = rewardHistoryDescription;
    return data;
  }
}
