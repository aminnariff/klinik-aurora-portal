class UpdateVoucherRequest {
  String? voucherId;
  String? voucherName;
  String? voucherDescription;
  String? voucherCode;
  int? voucherPoint;
  int? voucherStatus;
  String? voucherStartDate;
  String? voucherEndDate;

  UpdateVoucherRequest({
    this.voucherId,
    this.voucherName,
    this.voucherDescription,
    this.voucherCode,
    this.voucherPoint,
    this.voucherStatus,
    this.voucherStartDate,
    this.voucherEndDate,
  });

  UpdateVoucherRequest.fromJson(Map<String, dynamic> json) {
    voucherId = json['voucherId'];
    voucherName = json['voucherName'];
    voucherDescription = json['voucherDescription'];
    voucherCode = json['voucherCode'];
    voucherPoint = json['voucherPoint'];
    voucherStatus = json['voucherStatus'];
    voucherStartDate = json['voucherStartDate'];
    voucherEndDate = json['voucherEndDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['voucherId'] = voucherId;
    data['voucherName'] = voucherName;
    data['voucherDescription'] = voucherDescription;
    data['voucherCode'] = voucherCode;
    data['voucherPoint'] = voucherPoint;
    data['voucherStatus'] = voucherStatus;
    data['voucherStartDate'] = voucherStartDate;
    data['voucherEndDate'] = voucherEndDate;
    return data;
  }
}
