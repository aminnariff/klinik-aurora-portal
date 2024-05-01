class CreatePointRequest {
  String? userId;
  int? pointType;
  int? totalPoint;
  String? referralUserId;
  String? voucherId;

  CreatePointRequest({
    this.userId,
    this.pointType,
    this.totalPoint,
    this.referralUserId,
    this.voucherId,
  });

  CreatePointRequest.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    pointType = json['pointType'];
    totalPoint = json['totalPoint'];
    referralUserId = json['referralUserId'];
    voucherId = json['voucherId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['pointType'] = pointType;
    data['totalPoint'] = totalPoint;
    data['referralUserId'] = referralUserId;
    data['voucherId'] = voucherId;
    return data;
  }
}
