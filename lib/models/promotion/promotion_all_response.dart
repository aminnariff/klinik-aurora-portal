class PromotionAllResponse {
  String? message;
  List<Data>? data;
  int? totalPage;
  int? totalCount;

  PromotionAllResponse({
    this.message,
    this.data,
    this.totalPage,
    this.totalCount,
  });

  PromotionAllResponse.fromJson(Map<String, dynamic> json) {
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
  String? promotionId;
  String? promotionName;
  String? promotionDescription;
  String? promotionTnc;
  String? voucherId;
  String? promotionStartDate;
  String? promotionEndDate;
  int? showOnStart;
  List<PromotionImage>? promotionImage;
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
    if (json['promotionImage'] != null) {
      promotionImage = <PromotionImage>[];
      json['promotionImage'].forEach((v) {
        promotionImage!.add(PromotionImage.fromJson(v));
      });
    }
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
    if (promotionImage != null) {
      data['promotionImage'] = promotionImage!.map((v) => v.toJson()).toList();
    }
    data['promotionStatus'] = promotionStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}

class PromotionImage {
  String? id;
  String? path;

  PromotionImage({this.id, this.path});

  PromotionImage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    path = json['path'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['path'] = path;
    return data;
  }
}
