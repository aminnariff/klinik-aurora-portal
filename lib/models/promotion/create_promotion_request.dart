import 'package:klinik_aurora_portal/models/document/file_attribute.dart';

class CreatePromotionRequest {
  final String promotionName;
  final String promotionDescription;
  final String? promotionTnc;
  final String? voucherId;
  final String promotionStartDate;
  final String promotionEndDate;
  final int showOnStart;
  List<FileAttribute> documents;

  CreatePromotionRequest({
    required this.promotionName,
    required this.promotionDescription,
    this.promotionTnc,
    this.voucherId,
    required this.promotionStartDate,
    required this.promotionEndDate,
    required this.showOnStart,
    required this.documents,
  });
}
