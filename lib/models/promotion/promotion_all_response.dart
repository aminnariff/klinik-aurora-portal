class PromotionAllResponse {
  String? message;
  List<Data>? data;

  PromotionAllResponse({this.message, this.data});

  PromotionAllResponse.fromJson(Map<String, dynamic> json) {
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
  String? promotionId;
  String? promotionName;
  String? promotionDescription;
  String? promotionTnc;
  String? voucherId;
  String? promotionStartDate;
  String? promotionEndDate;
  int? showOnStart;
  String? promotionImage;
  int? promotionStatus;
  String? createdDate;
  String? modifiedDate;

  Data(
      {this.promotionId,
      this.promotionName,
      this.promotionDescription,
      this.promotionTnc,
      this.voucherId,
      this.promotionStartDate,
      this.promotionEndDate,
      this.showOnStart,
      this.promotionImage,
      this.promotionStatus,
      this.createdDate,
      this.modifiedDate});

  Data.fromJson(Map<String, dynamic> json) {
    promotionId = json['promotionId'];
    promotionName = json['promotionName'];
    promotionDescription = json['promotionDescription'];
    promotionTnc = json['promotionTnc'];
    voucherId = json['voucherId'];
    promotionStartDate = json['promotionStartDate'];
    promotionEndDate = json['promotionEndDate'];
    showOnStart = json['showOnStart'];
    promotionImage = json['promotionImage'];
    promotionStatus = json['promotionStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['promotionId'] = promotionId;
    data['promotionName'] = promotionName;
    data['promotionDescription'] = promotionDescription;
    data['promotionTnc'] = promotionTnc;
    data['voucherId'] = voucherId;
    data['promotionStartDate'] = promotionStartDate;
    data['promotionEndDate'] = promotionEndDate;
    data['showOnStart'] = showOnStart;
    data['promotionImage'] = promotionImage;
    data['promotionStatus'] = promotionStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
