class CreateRewardHistoryRequest {
  String? rewardId;
  String? pointTransactionId;
  String? rewardHistoryDescription;

  CreateRewardHistoryRequest({
    this.rewardId,
    this.pointTransactionId,
    this.rewardHistoryDescription,
  });

  CreateRewardHistoryRequest.fromJson(Map<String, dynamic> json) {
    rewardId = json['rewardId'];
    pointTransactionId = json['pointTransactionId'];
    rewardHistoryDescription = json['rewardHistoryDescription'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rewardId'] = rewardId;
    data['pointTransactionId'] = pointTransactionId;
    data['rewardHistoryDescription'] = rewardHistoryDescription;
    return data;
  }
}
