class RewardAllResponse {
  String? message;
  List<Data>? data;
  int? totalPage;
  int? totalCount;

  RewardAllResponse({
    this.message,
    this.data,
    this.totalPage,
    this.totalCount,
  });

  RewardAllResponse.fromJson(Map<String, dynamic> json) {
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
  String? rewardId;
  String? rewardName;
  String? rewardDescription;
  int? rewardPoint;
  int? totalReward;
  String? rewardImage;
  String? rewardStartDate;
  String? rewardEndDate;
  int? rewardStatus;
  String? createdDate;
  String? modifiedDate;

  Data(
      {this.rewardId,
      this.rewardName,
      this.rewardDescription,
      this.rewardPoint,
      this.totalReward,
      this.rewardImage,
      this.rewardStartDate,
      this.rewardEndDate,
      this.rewardStatus,
      this.createdDate,
      this.modifiedDate});

  Data.fromJson(Map<String, dynamic> json) {
    rewardId = json['rewardId'];
    rewardName = json['rewardName'];
    rewardDescription = json['rewardDescription'];
    rewardPoint = json['rewardPoint'];
    totalReward = json['totalReward'];
    rewardImage = json['rewardImage'];
    rewardStartDate = json['rewardStartDate'];
    rewardEndDate = json['rewardEndDate'];
    rewardStatus = json['rewardStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rewardId'] = rewardId;
    data['rewardName'] = rewardName;
    data['rewardDescription'] = rewardDescription;
    data['rewardPoint'] = rewardPoint;
    data['totalReward'] = totalReward;
    data['rewardImage'] = rewardImage;
    data['rewardStartDate'] = rewardStartDate;
    data['rewardEndDate'] = rewardEndDate;
    data['rewardStatus'] = rewardStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
