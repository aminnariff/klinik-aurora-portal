class UpdatePromotionRequest {
  final String promotionId;
  final String promotionName;
  final String promotionDescription;
  final String? promotionTnc;
  final String? voucherId;
  final String promotionStartDate;
  final String promotionEndDate;
  final bool showOnStart;
  final bool promotionStatus;

  UpdatePromotionRequest({
    required this.promotionId,
    required this.promotionName,
    required this.promotionDescription,
    this.promotionTnc,
    this.voucherId,
    required this.promotionStartDate,
    required this.promotionEndDate,
    required this.showOnStart,
    required this.promotionStatus,
  });
}
