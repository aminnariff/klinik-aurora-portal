class UpdateRewardRequest {
  String? rewardId;
  String? rewardName;
  String? rewardDescription;
  int? rewardPoint;
  int? rewardStatus;
  int? totalReward;
  String? rewardStartDate;
  String? rewardEndDate;
  String? rewardImage;

  UpdateRewardRequest(
      {this.rewardId,
      this.rewardName,
      this.rewardDescription,
      this.rewardPoint,
      this.rewardStatus,
      this.totalReward,
      this.rewardStartDate,
      this.rewardEndDate,
      this.rewardImage});

  UpdateRewardRequest.fromJson(Map<String, dynamic> json) {
    rewardId = json['rewardId'];
    rewardName = json['rewardName'];
    rewardDescription = json['rewardDescription'];
    rewardPoint = json['rewardPoint'];
    rewardStatus = json['rewardStatus'];
    totalReward = json['totalReward'];
    rewardStartDate = json['rewardStartDate'];
    rewardEndDate = json['rewardEndDate'];
    rewardImage = json['rewardImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rewardId'] = rewardId;
    data['rewardName'] = rewardName;
    data['rewardDescription'] = rewardDescription;
    data['rewardPoint'] = rewardPoint;
    data['rewardStatus'] = rewardStatus;
    data['totalReward'] = totalReward;
    data['rewardStartDate'] = rewardStartDate;
    data['rewardEndDate'] = rewardEndDate;
    if (rewardImage != null) data['rewardImage'] = rewardImage;
    return data;
  }
}
