class CreateRewardRequest {
  String? rewardName;
  String? rewardDescription;
  int? rewardPoint;
  int? totalReward;
  String? rewardStartDate;
  String? rewardEndDate;

  CreateRewardRequest(
      {this.rewardName,
      this.rewardDescription,
      this.rewardPoint,
      this.totalReward,
      this.rewardStartDate,
      this.rewardEndDate});

  CreateRewardRequest.fromJson(Map<String, dynamic> json) {
    rewardName = json['rewardName'];
    rewardDescription = json['rewardDescription'];
    rewardPoint = json['rewardPoint'];
    totalReward = json['totalReward'];
    rewardStartDate = json['rewardStartDate'];
    rewardEndDate = json['rewardEndDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rewardName'] = rewardName;
    data['rewardDescription'] = rewardDescription;
    data['rewardPoint'] = rewardPoint;
    data['totalReward'] = totalReward;
    data['rewardStartDate'] = rewardStartDate;
    data['rewardEndDate'] = rewardEndDate;
    return data;
  }
}
