import 'package:klinik_aurora_portal/models/document/file_attribute.dart';

class UpdateBranchRequest {
  final String branchId;
  final String? branchName;
  final String? phoneNumber;
  final String? address;
  final String? postcode;
  final String? city;
  final String? state;
  FileAttribute? branchImage;

  UpdateBranchRequest({
    required this.branchId,
    required this.branchName,
    required this.phoneNumber,
    required this.address,
    required this.postcode,
    required this.city,
    required this.state,
    required this.branchImage,
  });
}
