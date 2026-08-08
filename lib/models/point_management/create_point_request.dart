class CreatePointRequest {
  String? userId;
  int? pointType;
  int? totalPoint;
  String? referralUserId;
  String? voucherId;
  String? rewardId;
  String? pointDescription;

  /// Ringgit paid. When present on a spending transaction the server
  /// recalculates the award itself — applying the live campaign multiplier and
  /// any [modifierIds] — and ignores [totalPoint].
  double? amount;

  /// Point modifiers selected by the operator, resolved and re-validated
  /// server-side so an expired or deleted one cannot be applied.
  List<String>? modifierIds;

  CreatePointRequest({
    this.userId,
    this.pointType,
    this.totalPoint,
    this.referralUserId,
    this.voucherId,
    this.rewardId,
    this.pointDescription,
    this.amount,
    this.modifierIds,
  });

  CreatePointRequest.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    pointType = json['pointType'];
    totalPoint = json['totalPoint'];
    referralUserId = json['referralUserId'];
    voucherId = json['voucherId'];
    rewardId = json['rewardId'];
    pointDescription = json['pointDescription'];
    amount = (json['amount'] as num?)?.toDouble();
    modifierIds = json['modifierIds'] != null ? List<String>.from(json['modifierIds']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['pointType'] = pointType;
    data['totalPoint'] = totalPoint;
    data['referralUserId'] = referralUserId;
    data['voucherId'] = voucherId;
    data['rewardId'] = rewardId;
    data['pointDescription'] = pointDescription;
    if (amount != null) {
      data['amount'] = amount;
    }
    if (modifierIds != null && modifierIds!.isNotEmpty) {
      data['modifierIds'] = modifierIds;
    }
    return data;
  }
}
