class VoucherAllResponse {
  String? message;
  List<Data>? data;

  VoucherAllResponse({this.message, this.data});

  VoucherAllResponse.fromJson(Map<String, dynamic> json) {
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
  String? voucherId;
  String? voucherName;
  String? voucherCode;
  Null voucherDescription;
  int? voucherPoint;
  int? voucherStatus;
  String? createdDate;
  String? modifiedDate;

  Data(
      {this.voucherId,
      this.voucherName,
      this.voucherCode,
      this.voucherDescription,
      this.voucherPoint,
      this.voucherStatus,
      this.createdDate,
      this.modifiedDate});

  Data.fromJson(Map<String, dynamic> json) {
    voucherId = json['voucherId'];
    voucherName = json['voucherName'];
    voucherCode = json['voucherCode'];
    voucherDescription = json['voucherDescription'];
    voucherPoint = json['voucherPoint'];
    voucherStatus = json['voucherStatus'];
    createdDate = json['createdDate'];
    modifiedDate = json['modifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['voucherId'] = voucherId;
    data['voucherName'] = voucherName;
    data['voucherCode'] = voucherCode;
    data['voucherDescription'] = voucherDescription;
    data['voucherPoint'] = voucherPoint;
    data['voucherStatus'] = voucherStatus;
    data['createdDate'] = createdDate;
    data['modifiedDate'] = modifiedDate;
    return data;
  }
}
