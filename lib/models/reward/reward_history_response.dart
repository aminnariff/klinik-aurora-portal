class RewardHistoryResponse {
  String? message;
  List<Data>? data;

  RewardHistoryResponse({this.message, this.data});

  RewardHistoryResponse.fromJson(Map<String, dynamic> json) {
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
  String? rewardHistoryId;
  String? rewardId;
  String? pointTransactionId;
  String? rewardHistoryDescription;
  String? rewardHistoryImage;
  int? rewardHistoryStatus;
  String? rewardHistoryCreatedDate;
  String? rewardHistoryModifiedDate;

  Data(
      {this.rewardHistoryId,
      this.rewardId,
      this.pointTransactionId,
      this.rewardHistoryDescription,
      this.rewardHistoryImage,
      this.rewardHistoryStatus,
      this.rewardHistoryCreatedDate,
      this.rewardHistoryModifiedDate});

  Data.fromJson(Map<String, dynamic> json) {
    rewardHistoryId = json['rewardHistoryId'];
    rewardId = json['rewardId'];
    pointTransactionId = json['pointTransactionId'];
    rewardHistoryDescription = json['rewardHistoryDescription'];
    rewardHistoryImage = json['rewardHistoryImage'];
    rewardHistoryStatus = json['rewardHistoryStatus'];
    rewardHistoryCreatedDate = json['rewardHistoryCreatedDate'];
    rewardHistoryModifiedDate = json['rewardHistoryModifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rewardHistoryId'] = rewardHistoryId;
    data['rewardId'] = rewardId;
    data['pointTransactionId'] = pointTransactionId;
    data['rewardHistoryDescription'] = rewardHistoryDescription;
    data['rewardHistoryImage'] = rewardHistoryImage;
    data['rewardHistoryStatus'] = rewardHistoryStatus;
    data['rewardHistoryCreatedDate'] = rewardHistoryCreatedDate;
    data['rewardHistoryModifiedDate'] = rewardHistoryModifiedDate;
    return data;
  }
}
