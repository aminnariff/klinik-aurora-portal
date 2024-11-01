class VoucherAllResponse {
  String? message;
  List<Data>? data;
  int? totalPage;
  int? totalCount;

  VoucherAllResponse({
    this.message,
    this.data,
    this.totalPage,
    this.totalCount,
  });

  VoucherAllResponse.fromJson(Map<String, dynamic> json) {
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
  String? voucherId;
  String? voucherName;
  String? voucherCode;
  String? voucherDescription;
  int? voucherPoint;
  String? voucherStartDate;
  String? voucherEndDate;
  int? voucherStatus;
  String? createdDate;
  String? modifiedDate;
  String? rewardId;

  Data({
    this.voucherId,
    this.voucherName,
    this.voucherCode,
    this.voucherDescription,
    this.voucherPoint,
    this.voucherStartDate,
    this.voucherEndDate,
    this.voucherStatus,
    this.createdDate,
    this.modifiedDate,
    this.rewardId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    voucherId = json['voucherId'];
    voucherName = json['voucherName'];
    voucherCode = json['voucherCode'];
    voucherDescription = json['voucherDescription'];
    voucherPoint = json['voucherPoint'];
    voucherStartDate = json['voucherStartDate'];
    voucherEndDate = json['voucherEndDate'];
    voucherStatus = json['voucherStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
    rewardId = json['rewardId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['voucherId'] = voucherId;
    data['voucherName'] = voucherName;
    data['voucherCode'] = voucherCode;
    data['voucherDescription'] = voucherDescription;
    data['voucherPoint'] = voucherPoint;
    data['voucherStartDate'] = voucherStartDate;
    data['voucherEndDate'] = voucherEndDate;
    data['voucherStatus'] = voucherStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    data['rewardId'] = rewardId;
    return data;
  }
}
