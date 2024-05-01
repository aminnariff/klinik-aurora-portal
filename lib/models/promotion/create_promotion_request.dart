class CreatePromotionRequest {
  final String promotionName;
  final String promotionDescription;
  final String? promotionTnc;
  final String? voucherId;
  final String promotionStartDate;
  final String promotionEndDate;
  final int showOnStart;

  CreatePromotionRequest({
    required this.promotionName,
    required this.promotionDescription,
    this.promotionTnc,
    this.voucherId,
    required this.promotionStartDate,
    required this.promotionEndDate,
    required this.showOnStart,
  });
}
