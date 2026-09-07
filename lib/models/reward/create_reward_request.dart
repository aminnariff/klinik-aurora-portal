class CreateRewardRequest {
  String? rewardName;
  String? rewardDescription;
  int? rewardPoint;
  int? totalReward;
  String? rewardStartDate;
  String? rewardEndDate;
  String? rewardImage;

  CreateRewardRequest(
      {this.rewardName,
      this.rewardDescription,
      this.rewardPoint,
      this.totalReward,
      this.rewardStartDate,
      this.rewardEndDate,
      this.rewardImage});

  CreateRewardRequest.fromJson(Map<String, dynamic> json) {
    rewardName = json['rewardName'];
    rewardDescription = json['rewardDescription'];
    rewardPoint = json['rewardPoint'];
    totalReward = json['totalReward'];
    rewardStartDate = json['rewardStartDate'];
    rewardEndDate = json['rewardEndDate'];
    rewardImage = json['rewardImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rewardName'] = rewardName;
    data['rewardDescription'] = rewardDescription;
    data['rewardPoint'] = rewardPoint;
    data['totalReward'] = totalReward;
    data['rewardStartDate'] = rewardStartDate;
    data['rewardEndDate'] = rewardEndDate;
    if (rewardImage != null) data['rewardImage'] = rewardImage;
    return data;
  }
}
