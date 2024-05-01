class CreateVoucherRequest {
  String? voucherName;
  String? voucherDescription;
  String? voucherCode;
  int? voucherPoint;
  String? voucherStartDate;
  String? voucherEndDate;

  CreateVoucherRequest(
      {this.voucherName,
      this.voucherDescription,
      this.voucherCode,
      this.voucherPoint,
      this.voucherStartDate,
      this.voucherEndDate});

  CreateVoucherRequest.fromJson(Map<String, dynamic> json) {
    voucherName = json['voucherName'];
    voucherDescription = json['voucherDescription'];
    voucherCode = json['voucherCode'];
    voucherPoint = json['voucherPoint'];
    voucherStartDate = json['voucherStartDate'];
    voucherEndDate = json['voucherEndDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['voucherName'] = voucherName;
    data['voucherDescription'] = voucherDescription;
    data['voucherCode'] = voucherCode;
    data['voucherPoint'] = voucherPoint;
    data['voucherStartDate'] = voucherStartDate;
    data['voucherEndDate'] = voucherEndDate;
    return data;
  }
}
